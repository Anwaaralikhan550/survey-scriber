p = r'E:/survey-scriber/tool/desktop_editor/src/useEditor.js'
t = open(p, encoding='utf-8').read()


def rep(a, b):
    global t
    assert a in t, a[:70]
    t = t.replace(a, b, 1)


# newest answer wins: an older read that arrives late must not replace a newer one
rep("""  const loadLatest = useCallback(async () => {
    const fresh = await api.read(serverRef.current.reportId);
    fresh.content = normalise(fresh.content);
    setServer(fresh);
    return fresh;
  }, []);""", """  const loadSeq = useRef(0);
  const loadLatest = useCallback(async () => {
    const seq = ++loadSeq.current;
    const fresh = await api.read(serverRef.current.reportId);
    fresh.content = normalise(fresh.content);
    if (seq === loadSeq.current) setServer(fresh); // a slower, older answer never replaces a newer one
    return fresh;
  }, []);""")

rep("""  const save = useCallback(async () => {
    if (inFlight.current) {
      rerun.current = true;
      return;
    }
    if (['conflict'""", """  const doSave = useCallback(async () => {
    if (['conflict'""")
rep("""    inFlight.current = true;
    setSaveState('saving');""", """    setSaveState('saving');""")
rep("""      const next = fail(e);
      rerun.current = false; // a failed save is never repeated behind the user's back (conflict dialog, retry timer decide)
      setMessage""", """      const next = fail(e);
      setMessage""")
rep("""    } finally {
      inFlight.current = false;
      if (rerun.current) {
        rerun.current = false;
        save();
      }
    }
  }, [fail, loadLatest, setSaveState]);""", """    }
  }, [fail, loadLatest, setSaveState]);

  // One save at a time, in the order asked for. Anyone who asks (autosave, the Save button, a decision in the
  // review screen) gets a promise that finishes when the server has really answered, never earlier.
  const queue = useRef(Promise.resolve());
  const save = useCallback(() => {
    const run = queue.current.then(doSave);
    queue.current = run.catch(() => undefined);
    return run;
  }, [doSave]);""")
open(p, 'w', encoding='utf-8').write(t)
print('ok')
