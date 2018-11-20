@isTest
public class Test_ChooseOrigin {
    
    @isTest static void test_ChooseOrigin() {
        
        Test.startTest();
        
        TestUtilities.customSettings();     
        
        c_ChooseOrigin c  =new c_ChooseOrigin();         
        c.numCli ='numCli';
        c.choice ='DOCS' ;   
        c.bostamp ='xptoStamp';
        c.ftstamp ='FT2008XX';
        
        UtilClaims.Fatura fatura = new UtilClaims.Fatura( 'name', 'ftstamp', 'bostamp', system.now() );
        
        c.selectedLine = Json.serialize(new UtilClaims.NewClaimLine('name', 'ftstamp', 'bostamp', new List<UtilClaims.Fatura>{fatura}));
        
        c.showBackPageButton = false; 
        c.filter ='filter';
        c.choiceSucess = false;     
        c.isChosen  = false;
        
        UtilClaims.NewClaimLine novaLinha = new UtilClaims.NewClaimLine('name', 'ftstamp', 'bostamp', new List<UtilClaims.Fatura>{fatura});
        c.docs.add(novaLinha);
        
        c.originalDocs.add(novaLinha);
        
        
        c.getDocuments() ; 
        
        c.goBack();
        c.docs.get(0).selected = true;
        c.docs.get(0).fats = JSON.serialize(new List<UtilClaims.Fatura>{fatura});
        
        c.buildShowFaturas() ;
        c.checkLines();              
        c.filterList() ; 
        
        c.choice ='DOCS' ;      
        c.getDocuments() ; 
        Test.stopTest();
    }
    
}