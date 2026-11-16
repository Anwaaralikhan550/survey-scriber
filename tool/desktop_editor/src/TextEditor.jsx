import React, { useEffect, useRef } from 'react';
import { EditorContent, useEditor } from '@tiptap/react';
import Document from '@tiptap/extension-document';
import Paragraph from '@tiptap/extension-paragraph';
import Text from '@tiptap/extension-text';

// The report stores plain text; line breaks are "\n". Tiptap gives the editing surface only
// (paragraphs, caret, selection). Undo/redo is handled for the whole report in useEditor.js.
const toDoc = (text) => ({
  type: 'doc',
  content: String(text ?? '')
    .split('\n')
    .map((line) => (line ? { type: 'paragraph', content: [{ type: 'text', text: line }] } : { type: 'paragraph' })),
});
const toText = (editor) => editor.getText({ blockSeparator: '\n' });

export default function TextEditor({ value, onChange, onBlur, autoFocus, label, editable = true, placeholder }) {
  const last = useRef(value ?? '');
  const editor = useEditor({
    extensions: [Document, Paragraph, Text],
    content: toDoc(value),
    editable,
    autofocus: autoFocus ? 'end' : false,
    immediatelyRender: true,
    editorProps: { attributes: { 'aria-label': label, 'aria-multiline': 'true', role: 'textbox', class: 'pm' } },
    onUpdate: ({ editor: ed }) => {
      last.current = toText(ed);
      onChange(last.current);
    },
    onBlur: () => onBlur && onBlur(),
  });

  // Take the caret as soon as the editor exists, so typing right after "Add paragraph" never reaches the button.
  useEffect(() => {
    if (editor && autoFocus) editor.commands.focus('end');
  }, [editor, autoFocus]);

  // Undo/redo or reload changed the value from outside: show it.
  useEffect(() => {
    if (!editor || (value ?? '') === last.current) return;
    last.current = value ?? '';
    editor.commands.setContent(toDoc(value), { emitUpdate: false });
  }, [value, editor]);

  useEffect(() => {
    if (editor) editor.setEditable(editable);
  }, [editable, editor]);

  const empty = !(value ?? '').length;
  return (
    <div className={`texteditor${empty ? ' is-empty' : ''}`} data-placeholder={placeholder || ''}>
      <EditorContent editor={editor} />
    </div>
  );
}
