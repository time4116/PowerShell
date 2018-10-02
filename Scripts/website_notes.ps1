<# 
Launching chrome via --disable-web-security switch will disable same origin policy.

For web application security all the modern browsers strictly follow a policy called “same origin policy”.
You will also need to enable CORS via your AWS API Gateway.
#>

cd "C:\Program Files (x86)\Google\Chrome\Application"
./chrome.exe --user-data-dir="Location of your website" --disable-web-security --incognito

<#
Launch your website to test with AWS API Gateway.
#>
cd "Location of your website"
python -m http.server 8080
