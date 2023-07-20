describe('My First Test', () => {
  it('Visits the API', () => {
    cy.visit('www.rcapz.net')
    cy.contains('visitor')
  })
})