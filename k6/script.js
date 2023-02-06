import http from 'k6/http';
import { check, sleep } from 'k6';

export function call_mimic_api(token, username) {
    const url = 'http://localhost:9000/anything';

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
    const username = Math.floor(Math.random() * 100000);

    const url = 'http://localhost:8200/v1/totp/keys/'+username;

    const post_data = JSON.stringify({
        'generate' : true,
        'exported': true,
        'issuer': 'vault',
        'account_name' : username,
        'period': '30'
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
            'x-vault-token': 'root'
        }
    }

    const responseCreateUser = http.post(url, post_data, params)

    const url2 = 'http://localhost:8200/v1/totp/code/'+username;

    const params2 = {
        headers: {
            'x-vault-token': 'root'
        }
    }

    const responseGenerate = http.get(url2, params2);

    console.log(responseGenerate);

    sleep(1);
    var totp = JSON.parse(responseGenerate.body)

    const responseValidate = call_mimic_api(totp.data.code, username)

    console.log(responseValidate)
    check(responseGenerate, { 'status was 200 from Generate TOTP': (r) => r.status == 200 });
    check(responseValidate, { 'status was 200 from Mimic API': (r) => r.status == 200 });
    sleep(1);
}
