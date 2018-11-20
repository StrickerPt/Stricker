public class c_PDFPackingList {
    public String lang {get;set;}
    public Opportunity opp{get;set;}
    public Decimal auxkilo {get;set;}//auxiliar de formula
    public Decimal totalPeso {get;set;}
    public Decimal totalLPeso {get;set;}
    public Long caixas {get;set;}
    
    public c_PDFPackingList(ApexPages.StandardController controller){
        auxkilo = 1;//peso da caixa
        opp = [Select id, Idioma_para_documentos__c,
               (select id, ProductCode, Product2.Tamanho__c, Codigo_de_cor__c, Product2.Taric__c, Quantity, Peso__c, Product2.Nome_para_user__c,
                Product2.Peso_caixa__c,Product2.Caixa_exterior_unidades__c, N_de_caixas__c
                from OpportunityLineItems Where Product2.RecordType.DeveloperName = 'Produto') 
               From Opportunity Where Id = :controller.getId()];
        lang = opp.Idioma_para_documentos__c;
        
        totalPeso = 0;
        totalLPeso = 0;
        Decimal auxCaixas = 0;
        
        for(OpportunityLineItem oli : opp.OpportunityLineItems){
            totalPeso += (Decimal.valueOf(oli.Product2.Peso_caixa__c.replaceAll(',', '.'))*oli.N_de_caixas__c);
            totalLPeso += ((Decimal.valueOf(oli.Product2.Peso_caixa__c.replaceAll(',', '.'))*oli.N_de_caixas__c)-(auxkilo*oli.N_de_caixas__c));
            auxCaixas += oli.N_de_caixas__c;
            
        }
        totalPeso = totalPeso.stripTrailingZeros().setScale(2);
        totalLPeso = totalLPeso.stripTrailingZeros().setScale(2);
        caixas = auxCaixas.round(System.RoundingMode.UP);
    }
    
    public static String getLogoUrl(){
        List<Document> lstDocument = [Select Id,Name,LastModifiedById from Document where DeveloperName = 'Logo' limit 1];
        if(!lstDocument.isEmpty()){
            string strOrgId = UserInfo.getOrganizationId();
            string orgInst = URL.getSalesforceBaseUrl().getHost();
            orgInst = orgInst.substring(0, orgInst.indexOf('.')) + '.content.force.com';
            string strDocUrl = URL.getSalesforceBaseUrl().getProtocol() + '://c.' +
                orgInst + '/servlet/servlet.ImageServer?id=' + lstDocument[0].Id + '&oid=' + strOrgId;
            return strDocUrl;
        }
        return '';
    }
}