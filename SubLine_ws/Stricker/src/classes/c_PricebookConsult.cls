public class c_PricebookConsult {

    public List<SelectOption> filtros {get;set;}
    public String selectFiltro {get;set;}
    public Id prodId {get;set;}
    public List<String> nPrices {get;set;}
    public Map<String, String> intEscalaoMap {get;set;}
    public List<PricebookEntry> pbes {get;set;}
    public Boolean isCustomizacao {get;set;}
    public c_PricebookConsult(ApexPages.StandardController controller){
        prodId = controller.getId();
        intEscalaoMap = new Map<String,String>{'1' => 'A','2' => 'B','3' => 'C','4' => 'D','5' => 'E','6' => 'F','7' => 'G','8' => 'H',
        '9' => 'I','10' => 'J'};
        filtros = new List<SelectOption>();
        filtros.add(new selectOption('1', Label.Preco + ' ' + Label.Quantidade));
        filtros.add(new selectOption('2', Label.Preco + ' ' + SobjectType.Account.Fields.Escalao_Hidea__c.Label));
        selectFiltro = '1';
        /*markets
        for(Pricebook2 pb : [Select Id, Name From Pricebook2 Where Id In (Select Pricebook2Id from PricebookEntry Where Product2Id = :prodId) and isStandard = false]){
             markets.add(new selectOption(pb.Id, pb.Name));
        }
        
        selectedMarket = markets.isEmpty() ? null : markets.get(0).getValue();
        pbes = [Select Id, Name, CurrencyIsoCode, Custo_Adicional__c,Maximo_1__c,Maximo_2__c,
                Maximo_3__c,Maximo_4__c,Maximo_5__c,Maximo_6__c,Maximo_7__c,Maximo_8__c,Maximo_9__c,Maximo_10__c,Minimo_1__c,
                Minimo_2__c,Minimo_3__c,Minimo_4__c,Minimo_5__c,Minimo_6__c,Minimo_7__c,Minimo_8__c,Minimo_9__c,Minimo_10__c,
                Preco_1__c,Preco_2__c,Preco_3__c,Preco_4__c,Preco_5__c,Preco_6__c,Preco_7__c,Preco_8__c,Preco_9__c,Preco_10__c,
                Preco_A__c,Preco_B__c,Preco_C__c,Preco_D__c,Preco_E__c,Preco_F__c,Preco_G__c,Preco_H__c,Preco_I__c,Preco_J__c
                From PricebookEntry Where Product2Id = :prodId And Pricebook2Id = :selectedMarket];
        */
        
        nPrices = new List<String>();
        for(Integer i = 1; i <= c_AddProduct.FIELDSQTD ; i++){
            nPrices.add(String.valueOf(i));
        }
        pbes = [Select Id, Name, Pricebook2.Mercado__c, CurrencyIsoCode, Custo_Adicional__c,Maximo_1__c,Maximo_2__c,
                Maximo_3__c,Maximo_4__c,Maximo_5__c,Maximo_6__c,Maximo_7__c,Maximo_8__c,Maximo_9__c,Maximo_10__c,Minimo_1__c,
                Minimo_2__c,Minimo_3__c,Minimo_4__c,Minimo_5__c,Minimo_6__c,Minimo_7__c,Minimo_8__c,Minimo_9__c,Minimo_10__c,
                Preco_1__c,Preco_2__c,Preco_3__c,Preco_4__c,Preco_5__c,Preco_6__c,Preco_7__c,Preco_8__c,Preco_9__c,Preco_10__c,
                Preco_A__c,Preco_B__c,Preco_C__c,Preco_D__c,Preco_E__c,Preco_F__c,Preco_G__c,Preco_H__c,Preco_I__c,Preco_J__c,
                Product2.RecordType.DeveloperName
                From PricebookEntry Where Product2Id = :prodId and Pricebook2.isStandard = false ORDER by Pricebook2.Mercado__c Asc];
        //<Keidy>//
        Product2 produto = [Select RecordType.DeveloperName From Product2 Where Id = :prodId];
        isCustomizacao = produto.RecordType.DeveloperName == 'Customizacao';
        //</Keidy>//
    }
}