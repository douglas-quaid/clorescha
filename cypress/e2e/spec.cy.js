describe('My First Test', () => {

  let count1; //Counter for first website visit
  let count2; //Counter for second website visit

  it('First Visit to API', () => {
    cy.visit('www.rcapz.net')
    cy.wait(1000)
    cy.get('#demo').invoke('text').as('visitText1') //Get visitor count message then splice out count value
    cy.get('@visitText1').then((visitText1) => {
      count1 = visitText1.split(' ')[4]
    })
  })

  it('Second Visit to API', () => {
    cy.visit('www.rcapz.net')
    cy.wait(1000)
    cy.get('#demo').invoke('text').as('visitText2') //Get visitor count message then splice out count value
    cy.get('@visitText2').then((visitText2) => {
      count2 = visitText2.split(' ')[4]
    })
  })

  it('Compare API Values', () => {
  expect(parseInt(count1)).be.lt(parseInt(count2));
  })

})


