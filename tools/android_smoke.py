"""Run against the dedicated Xike QA emulator after installing a normal debug APK.
Requires integration-test persisted session/attempt data; never targets the original app.
"""
import json,subprocess,time
from pathlib import Path
adb='/Users/quocthanhvu/Library/Android/sdk/platform-tools/adb';package='max.xike.hihi'
def run(*args):return subprocess.check_output([adb,*args],text=True)
def state():return json.loads(run('shell','run-as',package,'cat','app_flutter/GetStorage.gs'))
def launch():run('shell','am','start','-n',package+'/.MainActivity');time.sleep(5)
run('shell','am','force-stop',package);launch();before=state()
assert len(before.get('sessions',[]))==1,'Completed integration session did not persist'
assert len(before.get('attempts',[]))==1,'Stopwatch attempt did not persist'
run('shell','input','tap','540','700')
for i in range(30):
 time.sleep(1)
 if i in [3,8]:run('shell','input','tap','540','700')
 if state().get('activeSession'):break
else:raise AssertionError('Breathing session did not start from native UI')
time.sleep(2);run('shell','am','force-stop',package);launch();after=state()
assert 'activeSession' not in after,'Stale session marker survived restart'
assert len(after.get('sessions',[]))==len(before.get('sessions',[])),'Interrupted session counted as complete'
assert before['settings']==after['settings'],'Settings not restored'
assert any('gián đoạn do tiến trình' in line for line in after['logs']),'Missing interrupted session log'
result={'persistence_restart':'passed','completed_sessions':len(after['sessions']),'stopwatch_attempts':len(after['attempts']),'settings_restored':after['settings'],'interrupted_session_not_completed':True,'active_marker_cleared':True}
Path('artifacts/process-restart.json').write_text(json.dumps(result,indent=2,ensure_ascii=False));print(json.dumps(result,ensure_ascii=False))
