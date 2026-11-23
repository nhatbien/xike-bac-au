"""Cold-start persistence check on the dedicated iOS QA Simulator only."""
import json,subprocess,time
from pathlib import Path
udid='A6DE8661-7AFB-4E8E-9FA9-B6AB8CEE02E9';bundle='vn.xike.xikeBacAu'
def sim(*args):return subprocess.check_output(['xcrun','simctl',*args],text=True).strip()
def state():
 root=Path(sim('get_app_container',udid,bundle,'data'))
 return json.loads((root/'Documents/GetStorage.gs').read_text())
before=state()
assert len(before.get('sessions',[]))==1
assert len(before.get('attempts',[]))==1
sim('launch',udid,bundle);time.sleep(4);after=state()
assert before['sessions']==after['sessions']
assert before['attempts']==after['attempts']
assert before['settings']==after['settings']
Path('artifacts/ios/persistence-check.json').write_text(json.dumps({'cold_start':'passed','sessions':len(after['sessions']),'attempts':len(after['attempts']),'settings_preserved':True},indent=2))
# Leave the QA app with default settings and no test history.
sim('terminate',udid,bundle);sim('uninstall',udid,bundle)
sim('install',udid,'build/ios/iphonesimulator/Runner.app');sim('launch',udid,bundle);time.sleep(4)
sim('io',udid,'screenshot','artifacts/ios/iphone-home.png')
print('PASS: cold-start persistence; QA app reset and launched with normal main.dart')
