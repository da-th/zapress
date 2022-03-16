/* Here are the first API tests. one can find some hints about it in the
README.md. */

describe('OWASP juice shop - API', () => {

  it('Login', () => {
    cy.api({
      method: 'POST',
      url: '/rest/user/login',
      body: {
        email: 'mc.safesearch@juice-sh.op',
        password: 'Mr. N00dles'
      }
    }).then(
      (response) => {
        expect(response.status).to.eq(200),
        expect(response.body.authentication.umail).to.eq('mc.safesearch@juice-sh.op'),
        cy.log(response.body.authentication.token)
          .as('token'),
        cy.log(response.duration)
          .as('duration')
      });
  });

  it('Get legal text', () => {
    cy.api({
      method: 'GET',
      url: '/ftp/legal.md'
    }).then(
      (response) => {
        expect(response.status).to.eq(200),
        cy.log(response.body)
          .as('legal'),
        cy.log(response.duration)
          .as('duration')
      });
    });
  });
