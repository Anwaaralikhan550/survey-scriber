p = r'E:/survey-scriber/tool/desktop_editor/src/useEditor.js'
t = open(p, encoding='utf-8').read()


def rep(a, b, count=1):
    global t
    assert a in t, a[:70]
    t = t.replace(a, b, count)


rep("  const [cur, setCurState] = useState(() => normalise(initial.content));", "  const [cur, setCurRaw] = useState(() => normalise(initial.content));")
rep("  serverRef.current = server;\n  curRef.current = cur;\n", """  serverRef.current = server;
  curRef.current = cur;
  // The refs are what the save queue reads. They are updated at the moment the state is set, not at the next render,
  // so a save that starts right after another one finished never works from the answer before it.
  const setCurState = useCallback((v) => {
    curRef.current = v;
    setCurRaw(v);
  }, []);
  const setServerNow = useCallback((v) => {
    serverRef.current = v;
    setServer(v);
  }, []);
""")
rep("    if (seq === loadSeq.current) setServer(fresh); // a slower, older answer never replaces a newer one", "    if (seq === loadSeq.current) setServerNow(fresh); // a slower, older answer never replaces a newer one")
rep("      setServer({ ...theirs, content: normalise(theirs.content) });", "      setServerNow({ ...theirs, content: normalise(theirs.content) });")
open(p, 'w', encoding='utf-8').write(t)
print('ok')
