describe('OWASP juice shop - API', () => {

    it.only('Login', () => {
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
          cy.log(response.body.authentication.token).as('token'),
          cy.log(response.duration).as('duration')
        })
    })
  })
