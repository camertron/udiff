use magnus::{function, method, prelude::*, Error, RArray, Ruby};

#[magnus::wrap(class = "Udiff::PatchSetImpl")]
struct PatchSet {
    patch_set: unidiff::PatchSet
}

#[magnus::wrap(class = "Udiff::PatchedFileImpl")]
struct PatchedFile {
    index: usize
}

impl PatchedFile {
    fn source_file(&self, patch_set: &PatchSet) -> String {
        patch_set.patch_set.files()[self.index].source_file.clone()
    }

    fn target_file(&self, patch_set: &PatchSet) -> String {
        patch_set.patch_set.files()[self.index].target_file.clone()
    }

    fn apply(ruby: &Ruby, rust_self: &Self, input: String, patch_set: &PatchSet) -> Result<String, Error> {
        PatchedFile::apply_with_fuzz(ruby, rust_self, input, patch_set, 3, 1)
    }

    fn apply_with_fuzz(ruby: &Ruby, rust_self: &Self, input: String, patch_set: &PatchSet, fuzz: usize, min_context_matches: usize) -> Result<String, Error> {
        let file_patch = &patch_set.patch_set.files()[rust_self.index];
        let mut lines: Vec<String> = input.lines().map(|l| l.to_string()).collect();

        for hunk in file_patch.hunks().iter() {
            let original_start = hunk.source_start;
            let hunk_lines = hunk.lines();

            // Try offsets in range [-fuzz, +fuzz]
            let mut best_match = None;

            for offset in -(fuzz as isize)..=(fuzz as isize) {
                let try_start = original_start as isize + offset;

                if try_start < 0 || try_start as usize >= lines.len() {
                    continue;
                }

                let mut context_matches = 0;
                let mut mismatch = false;
                let mut cursor = try_start as usize;

                for line in hunk_lines.iter() {
                    if line.is_context() {
                        if cursor >= lines.len() || lines[cursor] != line.value.trim_end_matches('\n') {
                            mismatch = true;
                            break;
                        }

                        context_matches += 1;
                        cursor += 1;
                    } else if line.is_removed() {
                        cursor += 1;
                    }
                }

                if !mismatch && context_matches >= min_context_matches {
                    best_match = Some(try_start as usize);
                    break;
                }
            }

            let apply_at = match best_match {
                Some(pos) => pos,
                None => {
                    return Err(
                        Error::new(
                            ruby.exception_runtime_error(),
                            format!(
                                "Failed to apply hunk near line {} with fuzz {}",
                                hunk.target_start, fuzz
                            )
                        )
                    );
                }
            };

            // Apply changes
            let mut output = Vec::new();
            let mut cursor = apply_at;

            for line in hunk_lines {
                if line.is_context() {
                    output.push(lines[cursor].clone());
                    cursor += 1;
                } else if line.is_removed() {
                    cursor += 1;
                } else {
                    // added
                    output.push(line.value.trim_end_matches('\n').to_string());
                }
            }

            lines.splice(apply_at..(apply_at + hunk.source_length), output);
        }

        Ok(lines.join("\n"))
    }
}

impl PatchSet {
    fn new(src: String) -> Self {
        let mut patch = unidiff::PatchSet::new();
        patch.parse(src).unwrap();
        PatchSet { patch_set: patch }
    }

    fn files(&self) -> RArray {
        let array = RArray::with_capacity(self.patch_set.files().len());
        array.push(PatchedFile { index: 0 }).unwrap();
        array
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let udiff_module = ruby.define_module("Udiff")?;

    let patch_set_class = udiff_module.define_class("PatchSetImpl", ruby.class_object())?;
    patch_set_class.define_singleton_method("new", function!(PatchSet::new, 1))?;
    patch_set_class.define_method("files", method!(PatchSet::files, 0))?;

    let patched_file_class = udiff_module.define_class("PatchedFileImpl", ruby.class_object())?;
    patched_file_class.define_method("source_file", method!(PatchedFile::source_file, 1))?;
    patched_file_class.define_method("target_file", method!(PatchedFile::target_file, 1))?;
    patched_file_class.define_method("apply", method!(PatchedFile::apply, 2))?;

    Ok(())
}
