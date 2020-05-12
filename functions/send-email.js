var nodemailer = require('nodemailer');

let smtpConfig = {
    host: 'smtp.gmail.com',
    port: 465,
    secure: true, // use TLS
    auth: {
        user: 'temp', 
        pass: 'temp'
    }
};

function main(params) {
    return new Promise(function (resolve, reject) {
        let response = {
            code: 200,
            msg: 'E-mail was sent successfully!'
        };

        console.log(`passed parameters:` + JSON.stringify(params));
        
        if (!params.to_email) {
            response.msg = "Error: Destination e-mail was not provided.";
            response.code = 400;
        }
        else if (!params.action) {
            response.msg = "Error: Action was not provided.";
            response.code = 400;
        }
        else if (!params.from_email) {
            response.msg = "Error: Source e-mail was not provided.";
            response.code = 400;
        }
        else if (!params.password) {
            response.msg = "Error: Email password was not provided.";
            response.code = 400;
        }

        if (response.code != 200) {
            reject(response);
        }

        console.log(`Validation was successful, preparing to send email...`);

        sendEmail(params, function (email_response) {
            response.msg = email_response['msg'];
            response.code = email_response['code'];
            response.reason = email_response['reason'];
            console.log(`Email delivery response: (${email_response['code']}) ${response.msg}`);
            resolve(response);
        });

    });
}

function sendEmail(params, callback) {
    smtpConfig.auth.user = params.from_email;
    smtpConfig.auth.pass = params.password;
    let transporter = nodemailer.createTransport(smtpConfig);
    let mailOptions = {
        from: `IBM Cloud Functions automation <${smtpConfig.auth.user}>`,
        to: params.to_email,
        subject: `cloud function action invoked`,
        text: `The cloud function action to ${params.action} Terraform was invoked`
    };
    transporter.sendMail(mailOptions, function (error, info) {

        let email_response = {
            code: 200,
            msg: 'Email was sent successfully',
            reason: 'Success'
        };

        if (error) {
            email_response.msg = 'Error';
            email_response.code = 500;
            email_response.reason = error;
        }
        else {
            email_response.msg = info.response;
            email_response.code = 200;
            email_response.reason = info.response;
        }
        callback(email_response);
    });
}