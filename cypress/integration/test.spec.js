/* I have revised the test cases. Now they are almost independent of each other,
except the first test is responsible for setting the cookies correctly for the
following ones. */

before(() => {
  cy.clearCookies();
  cy.clearLocalStorage();
  //cy.credentials();
});

describe("OWASP juice shop - logged out", () => {

  before(() => {
    cy.credentials();
  });
  beforeEach(() => {
    cy.setCookie('cookieconsent_status', 'dismiss');
    cy.setCookie('welcomebanner_status', 'dismiss');
    cy.visit('/');
  });

  it.only("should type in credentials, press the login button and be logged in",
    () => {
    cy.get("button[aria-label='Show the shopping cart']").should("not.exist");

    cy.get("button#navbarAccount").click();
    cy.get("button#navbarLoginButton").click();

    cy.url().should("include", "login");

    //cy.get("#login-form").within(() => {
      /*cy.get("#email").type("mc.safesearch@juice-sh.op");
      cy.get("#password").type("Mr. N00dles");*/
      cy.get("#email").type(this.credentials.Email1);
      cy.get("#password").type(this.credentials.Password1);
      cy.get("#rememberMe").click();

      cy.get("#loginButton").click();
    //});

    cy.loggedIn();

    cy.getCookie('continueCode');
  });
});

describe("OWASP juice shop - logged in", () => {
  beforeEach(() => {
    cy.login('mc.safesearch@juice-sh.op', 'Mr. N00dles');
    cy.visit('/');
    cy.loggedIn();
  });

  it("should visit some subpages", () => {
    cy.visit("/#/about");
    cy.visit("/#/photo-wall");
  });

  it("should open profile and add username", () => {
    cy.visit("/profile");

    cy.get("#username").clear().type("someUsername");
    cy.get("#submit").click();

    cy.visit("/rest/user/data-export", { failOnStatusCode: false })
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
