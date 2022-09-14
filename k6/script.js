import http from 'k6/http';
import { check, sleep } from 'k6';

export function call_mimic_api(token, username) {
    const url = 'http://172.23.0.3:8000/anything';

    const payload = JSON.stringify({
        name: 'mkth',
        region: 'rs',
        mfa: {
            code: token
        }
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
            'Username': username
        },
    };

    return http.post(url, payload, params);
}

export default function () {
    var username = Math.floor(Math.random() * 100000);
    var url = 'http://172.23.0.3:8000/totp/generate/'+username;

    console.log(url);
    const responseGenerate = http.post(url);
    console.log(responseGenerate);
    sleep(1);
    var totp = JSON.parse(responseGenerate.body)
    const responseValidate = call_mimic_api(totp.token, username)

    console.log(responseValidate)
    check(responseGenerate, { 'status was 200 from Generate TOTP': (r) => r.status == 200 });
    check(responseValidate, { 'status was 200 from Mimic API': (r) => r.status == 200 });
    sleep(1);
}
