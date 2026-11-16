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
  // Texts this editor sent up that React has not yet shown back to it. Fast typing makes the screen lag behind the keys,
  // and an echo of an older text must never overwrite what has been typed since.
  const emitted = useRef([]);
  const editor = useEditor({
    extensions: [Document, Paragraph, Text],
    content: toDoc(value),
    editable,
    autofocus: autoFocus ? 'end' : false,
    immediatelyRender: true,
    editorProps: { attributes: { 'aria-label': label, 'aria-multiline': 'true', role: 'textbox', class: 'pm' } },
    onUpdate: ({ editor: ed }) => {
      last.current = toText(ed);
      emitted.current = [...emitted.current.slice(-49), last.current];
      onChange(last.current);
    },
    onBlur: () => onBlur && onBlur(),
    // Take the caret the moment the editor exists (before the first paint), so keys typed right after a click are not lost.
    onCreate: ({ editor: ed }) => {
      if (autoFocus) ed.commands.focus('end');
    },
  });

  // Take the caret as soon as the editor exists, so typing right after "Add paragraph" never reaches the button.
  useEffect(() => {
    if (editor && autoFocus) editor.commands.focus('end');
  }, [editor, autoFocus]);

  // Undo/redo or reload changed the value from outside: show it.
  useEffect(() => {
    if (!editor) return;
    const mine = emitted.current.indexOf(value ?? '');
    if (mine >= 0) {
      emitted.current.splice(0, mine + 1); // our own text coming back: nothing to do
      return;
    }
    if ((value ?? '') === last.current) return;
    emitted.current = [];
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
