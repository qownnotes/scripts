
## Overview

The ASCII Tree Factory plugin for QOwnNotes allows users to generate an ASCII tree representation from a given path structure. This can be particularly useful for visualizing directory structures or any hierarchical data within your notes.

## Installation

1. **Download the Plugin**: Save the `ASCII-Tree-Factory.qml`  file to your local machine.
2. **Add to QOwnNotes**:
   - Open QOwnNotes.
   - Navigate to `Settings` > `Scripting`.
   - Click on `Add script... > Add local script`.
   - Select the  `ASCII-Tree-Factory.qm` file in the script folder.
3. **Activate the Plugin**:
   - Go back to QOwnNotes.
   - In the `Scripting` settings, ensure that  `ASCII-Tree-Factory.qml` is listed and checked.

## Usage

1. **Select Text**: Highlight the text in your note that represents the path structure you want to convert into an ASCII tree.
2. **Run the Plugin**:
   - Right-click on the selected text.
   - Choose `Custom Actions` > `Generate ASCII tree from path`.

The plugin will replace the selected text (single or multi-line) with an ASCII tree representation.

## Example

### Input

```
root/folder1/file1.txt
root/folder2/file2.txt
root/folder2/subfolder1/file3.txt
```

### Output

```
root
  ├─folder1
  │ └─file1.txt
  └─folder2
    └─file2.txt
    └─subfolder1
      └─file3.txt
```

## Contributing

If you have suggestions or improvements, feel free to fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

Enjoy using the ASCII Tree Factory plugin to enhance your note-taking experience with QOwnNotes!
