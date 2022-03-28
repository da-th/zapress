Cypress.Commands.add('login', (email, password) => {
  // execute cookie setup, login and save session for later use
  cy.session([email, password], () => {
    cy.setCookie('cookieconsent_status', 'dismiss');
    cy.setCookie('welcomebanner_status', 'dismiss');

    cy.visit('/#/login');

    cy.get("#login-form").within(() => {
      cy.get("#email").type(email);
      cy.get("#password").type(password);
      cy.get("#rememberMe").click();
      cy.get("#loginButton").click();
    })
    // assert logged in by visible shopping cart button
    cy.get("button[aria-label='Show the shopping cart']").should("be.visible");
  })
});

Cypress.Commands.add('loggedIn', () => {
  cy.get("button[aria-label='Show the shopping cart']").should("be.visible");
});
