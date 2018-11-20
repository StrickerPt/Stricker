public class c_CobrancaAlerta {
    public Id idAcc {get;set;}
    public Integer alertType {get;set;}
    
    public Account getAccount(){
        return [Select id, Name, Divida_vencida__c, Numero_de_alertas_1__c, Numero_de_alertas_2__c, Numero_de_alertas_3__c, Numero_de_alertas_4__c, Tabela_de_precos__c From Account Where Id = :idAcc];
    }
    public String getcurrencySymbol(){
        return Utils.currencySymbol(ProductManager.mapISOCodes.get(getAccount().Tabela_de_precos__c));
    }
    public List<Documentos_financeiros__c> getDocs(){
        if(alertType == 1){
            return [Select id, Numero_de_documento__c, Valor_debito__c, Valor_debito_regularizado__c,Data_de_Validade__c,Valor_Regularizado__c, Valor_credito_regularizado__c, Valor_credito__c
                    From Documentos_financeiros__c 
                    Where Estado__c != 'Pago' 
                    And Tipo_de_documento__c In (1,5,6,9,16,17,24,25,26)
                    And Data_de_validade__c <= :system.today().addDays(7) And Data_de_validade__c >= :system.today()
                    And Conta__c = :idAcc];
        }else if(alertType == 2){
            return [Select id, Numero_de_documento__c, Valor_debito__c, Valor_debito_regularizado__c,Data_de_Validade__c,Valor_Regularizado__c, Valor_credito_regularizado__c, Valor_credito__c
                    From Documentos_financeiros__c 
                    Where Estado__c != 'Pago' 
                    And Tipo_de_documento__c In (1,5,6,9,16,17,24,25,26)
                    And Data_de_validade__c <= :system.today().addDays(-15) And Data_de_validade__c >= :system.today().addDays(-30)
                    And Conta__c = :idAcc];
        }else if(alertType == 3){
            return [Select id, Numero_de_documento__c, Valor_debito__c, Valor_debito_regularizado__c,Data_de_Validade__c,Valor_Regularizado__c, Valor_credito_regularizado__c, Valor_credito__c
                    From Documentos_financeiros__c 
                    Where Estado__c != 'Pago' 
                    And Tipo_de_documento__c In (1,5,6,9,16,17,24,25,26)
                    And Data_de_validade__c <= :system.today().addDays(-30) And Data_de_validade__c >= :system.today().addDays(-60)
                    And Conta__c = :idAcc];
        }else if(alertType == 4){
            return [Select id, Numero_de_documento__c, Valor_debito__c, Valor_debito_regularizado__c,Data_de_Validade__c,Valor_Regularizado__c, Valor_credito_regularizado__c, Valor_credito__c
                    From Documentos_financeiros__c 
                    Where Estado__c != 'Pago' 
                    And Tipo_de_documento__c In (1,5,6,9,16,17,24,25,26)
                    And Data_de_validade__c <= :system.today().addDays(-60)
                    And Conta__c = :idAcc];
        }
        return new List<Documentos_financeiros__c>();
    }
    
    
    public decimal getTotal(){
        Decimal sum = 0;
        for(Documentos_financeiros__c doc : getDocs()){
            Decimal deb = doc.Valor_debito__c != null ? doc.Valor_debito__c : 0;
            Decimal debReg = doc.Valor_debito_regularizado__c != null ? doc.Valor_debito_regularizado__c : 0;
            sum += deb - debReg;
        }
        return sum;
    }
    
    public decimal getTotalCred(){
        Decimal sum = 0;
        for(Documentos_financeiros__c doc : getDocs()){
            Decimal cred = doc.Valor_credito__c != null ? doc.Valor_credito__c : 0;
            Decimal credReg = doc.Valor_credito_regularizado__c != null ? doc.Valor_credito_regularizado__c : 0;
            sum += cred - credReg;
        }
        return sum;
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