# Learn how to make your apps more secure with Cypress & OWASP ZAP

 This set of apps build an environment to learn how to test for threads in an web app.

 1. [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) is an example shop
 with intentional build in insecureties. The challange is to find them.
 But this is more than only a shop. It shows you when you had discovered an insecurity
 or teach you in various lessons what they are and how to find them, as well. The
 project leader provides a book about this application and its use:
 - Online: https://pwning.owasp-juice.shop/
 - PDF/MOBI/EPUB: https://leanpub.com/juice-shop.
 2. [Cypress](https://www.cypress.io) is the new "Selenium", so an UI/E2E testing
 framework. It's awsome <find article linkto post here>
 3. [OWASP ZAP](https://www.zaproxy.org/) is a security scanner fpr web apps. It can
 find potential vulnerabilities by analyse traffic using a proxy, passive and active
 scan and more.

# Preconditions

1. (Required) [Docker](https://github.com/docker/docker-install) Do you need an
explanation, really? Container based virtualization of apps or their parts, provided as
service.

2. (Required) [Docker-Compose](https://github.com/docker/compose) is able to handle
docker container in its context or dependancies (networks between,...).

3. (Required) [NPM](https://github.com/npm/cli) is a java script package manager
(node.js).

4. (Optional but recommended) [NVM](https://github.com/nvm-sh/nvm) make id possible to switch between versions
of npm per project. So one can run the application in the matching npm version. Here
the recommended version is v12.15.0 . All other can fail because of not matching the needs of the system.
NOTE: After any version change one has to perform an "npm i" to install the dependancies!


# Inspiration
 Zapress was inspired by the project "jverhoelen/owasp-zap-with-entrypoint".
 Unfortunately this project seems to be abandond and had dependencies to an other not
 supported project of the same author.
 So I decided to build this new only whith dependencies which are well maintained.
