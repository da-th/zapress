/* I have revised the test cases. Now they are almost independent of each other,
except the first test is responsible for setting the cookies correctly for the
following ones. */

let credentials;

before(() => {
  cy.clearCookies();
  cy.clearLocalStorage();

  // get user data from /fixture/user.json
  cy.fixture('user').then((data) => {
        credentials = data;
    });
});

describe("OWASP juice shop - logged out", () => {
  before(() => {
  });
  beforeEach(() => {
    cy.setCookie('cookieconsent_status', 'dismiss');
    cy.setCookie('welcomebanner_status', 'dismiss');
    cy.visit('/');
  });

  it("should type in credentials, press the login button and be logged in",
    () => {
    cy.get("button[aria-label='Show the shopping cart']").should("not.exist");

    cy.get("button#navbarAccount").click();
    cy.get("button#navbarLoginButton").click();

    cy.url().should("include", "login");

    cy.get("#login-form").within(() => {
      cy.get("#email").type(credentials.email);
      cy.get("#password").type(credentials.password);
      cy.get("#rememberMe").click();

      cy.get("#loginButton").click();
    });

    cy.loggedIn();

    cy.getCookie('continueCode');
  });

  it("should visit some subpages", () => {
    cy.visit("/#/about");
    cy.visit("/#/photo-wall");
  });

  it("should open and close the item detail", () => {
    cy.get(".ribbon-card").first().click();
    cy.get("mat-dialog-container").should("exist");

    cy.get("button[aria-label='Close Dialog']").click();
    cy.get("mat-dialog-container").should("not.exist");
  });

  it("should visit the score board", () => {
    cy.visit("/#/score-board");
  });

  it("should enter XSS payload into the search field", () => {
    const payload = '<iframe src="javascript:alert(`xss`)">';

    cy.get("#searchQuery").click();
    cy.get("#mat-input-0").clear().type(payload) + '{enter}';
  });
});

describe("OWASP juice shop - logged in", () => {
  beforeEach(() => {
    cy.login(credentials.email, credentials.password);
    cy.visit('/');
    cy.loggedIn();
  });

  it("should open profile and add username", () => {
    cy.visit("/profile");

    cy.get("#username").clear().type("someUsername");
    cy.get("#submit").click();

    cy.visit("/rest/user/data-export", { failOnStatusCode: false })
  });

});
