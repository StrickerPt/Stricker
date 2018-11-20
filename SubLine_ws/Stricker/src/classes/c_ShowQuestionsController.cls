public without sharing class c_ShowQuestionsController {
    
    public Relatorio__c visit_report{get;set;}
    public Account conta {get;set;}
    public boolean reportApproved {get;set;}
    public boolean newWindow {get;set;}
    
    public Map<Id, Pergunta__c> questionMap {get;set;}
    public List<Pergunta__c> duringQuestions {get;set;}
    public List<Pergunta__c> afterQuestions {get;set;}
    public Map<Id, Resposta__c> answers {get;set;}
    public Map<Id, List<SelectedValue>> multipicklistvalues {get;set;}
    
    public List<SelectOption> selectFirstSupplier {get;set;}
    public List<SelectOption> selectSecondSupplier {get;set;}
    public List<SelectOption> selectThirdSupplier {get;set;}
    
    public List<SelectOption> selectFirstSegmentation {get;set;}
    public List<SelectOption> selectSecondSegmentation {get;set;}
    public List<SelectOption> selectThirdSegmentation {get;set;}
    
    public Map<id, List<SelectOption>> dropDownAnswers {get;set;}
    
    public List<SelectedMultipicklist> factoresSelectivos {get;set;} 
    public List<SelectedMultipicklist> gamaProdutos {get;set;}
    public List<SelectedMultipicklist> principaisProdutos {get;set;}
    public List<SelectedMultipicklist> marketingProprio {get;set;}
    
    public boolean isSucess {get;set;}
    public String errorMessage {get;set;}
    public String sucessMessage {get;set;}
    public String currencyIsoCode {get;set;}
    public c_ShowQuestionsController(ApexPages.StandardController stdController){
        this.visit_report = [select Id from Relatorio__c where Id = :stdController.getId()];
        init();
    }
    
    public void init(){
        newWindow = System.currentPageReference().getParameters().get('param1') == 'true';
        visit_report = [Select id,Template_de_relatorio__c,Primeiro_fornecedor__c,Segundo_fornecedor__c, Terceiro_fornecedor__c, Primeiro_volume_de_vendas__c, 
                        Segundo_volume_de_vendas__c, Terceiro_volume_de_vendas__c, Primeiro_Outro_fornecedor__c , Segundo_Outro_fornecedor__c,
                        Preechimento_de_relatorio__c, Terceiro_Outro_fornecedor__c,Conta__c
                        From Relatorio__c Where id = :visit_report.Id];
        conta = [Select Id,Volume_de_faturacao_global__c, Volume_de_compras_promocionais__c, Importacao_volume_negocio__c,X1_Segmentacao__c,
                 X2_Segmentacao__c, X3_Segmentacao__c, X1_Segmentacao_Percentagem__c, X2_Segmentacao_Percentagem__c, X3_Segmentacao_Percentagem__c,
                 Classe__c,Factores_seletivos__c,Gama_de_produtos__c,Numero_de_comerciais__c,Potencial_de_crescimento__c,Tipologia_de_clientes__c,
                 Impressao__c,Armazem_proprio__c,Principais_produtos_em_stock__c,Valor_em_stock_proprio__c,Origem_do_stock__c,Acoes_de_marketing_proprias__c,
                 Catalogo_proprio__c,Data_de_selecao__c,Numero_de_produtos_Stricker__c,X1_Fornecedor__c, X2_Fornecedor__c, X3_Fornecedor__c,
                 X1_Fornecedor_Volume_de_compras__c, X2_Fornecedor_Volume_de_compras__c, X3_Fornecedor_Volume_de_compras__c, CurrencyIsoCode,
                 Alt_Acoes_de_marketing_proprias__c, Alt_Armazem_proprio__c, Alt_Catalogo_proprio__c, Alt_Classe__c, Alt_Data_de_selecao__c, Alt_Factores_seletivos__c, 
                 Alt_Gama_de_produtos__c, Alt_Importacao_volume_negocio__c, Alt_Impressao__c, Alt_Numero_de_comerciais__c, Alt_Numero_de_produtos_Stricker__c,
                 Alt_Origem_do_stock__c, Alt_Potencial_de_crescimento__c, Alt_Principais_produtos_em_stock__c, Alt_Tipologia_de_clientes__c, Alt_Valor_em_stock_proprio__c, 
                 Alt_Volume_de_compras_promocionais__c, Alt_Volume_de_faturacao_global__c, Alt_X1_Fornecedor__c, Alt_X1_Fornecedor_Volume_de_compras__c, Alt_X1_Segmentacao__c, 
                 Alt_X1_Segmentacao_Percentagem__c, Alt_X2_Fornecedor__c, Alt_X2_Fornecedor_Volume_de_compras__c, Alt_X2_Segmentacao__c, Alt_X2_Segmentacao_Percentagem__c, 
                 Alt_X3_Fornecedor__c, Alt_X3_Fornecedor_Volume_de_compras__c, Alt_X3_Segmentacao__c, Alt_X3_Segmentacao_Percentagem__c
                 From Account 
                 Where Id = :visit_report.Conta__c];
        reportApproved = false;
        dropDownAnswers = new Map<Id,List<SelectOption>>();
        currencyIsoCode = Utils.currencySymbol(conta.CurrencyIsoCode);
        
        questionMap = new Map<Id, Pergunta__c>();
        multipicklistvalues = new Map<Id, List<SelectedValue>>();
        afterQuestions = new List<Pergunta__c>();
        duringQuestions = new List<Pergunta__c>();
        getQuestions();
        answers = new Map<Id, Resposta__c>();
        getAnswers();
        getPicklists();
        getSegmentationPicklists();
        factoresSelectivos = getMultipicklist(Account.Factores_seletivos__c.getDescribe());
        gamaProdutos = getMultipicklist(Account.Gama_de_produtos__c.getDescribe());
        principaisProdutos = getMultipicklist(Account.Principais_produtos_em_stock__c.getDescribe());
        marketingProprio = getMultipicklist(Account.Acoes_de_marketing_proprias__c.getDescribe());
    }
    public void getAnswers(){
        List<Resposta__c> newList = [Select Id, Name,Pergunta__r.RecordType.Name, Resposta_em_texto__c, Pergunta__c, Relatorio__c, Resposta_em_multipicklist__c, Resposta_em_checkbox__c, Resposta_em_moeda__c, Resposta_em_picklist__c, Resposta_em_numero__c, Resposta_preenchida__c 
                                     From Resposta__c Where Relatorio__r.Id = :visit_report.Id AND Pergunta__r.Ativa__c = true And Pergunta__c In :questionMap.keySet()];
        for(Resposta__c a : newList){
            answers.put(a.Pergunta__c, a);
            if(multipicklistvalues.containsKey(a.Pergunta__c)){
                for(SelectedValue sv : multipicklistvalues.get(a.Pergunta__c)){
                    if(a.Resposta_em_multipicklist__c != null){        
                        sv.selected = a.Resposta_em_multipicklist__c.contains(sv.value);
                    }
                }
            }
        }
    }
    
    public Void getQuestions(){
        Map<Id, RecordType> recordTypes = new Map<Id, RecordType> ([Select Id, Name, SobjectType From RecordType Where SobjectType = 'Pergunta__c']);
        system.debug(recordTypes);
        for(Pergunta__c q : [select Name, Pergunta__c, Id, Template_de_relatorio__c, Ativa__c, Opcoes_de_lista__c, N_A__c,RecordType.Name, Momento_de_pergunta__c
                             from Pergunta__c 
                             Where Ativa__c = true 
                             And Template_de_relatorio__c = :visit_report.Template_de_relatorio__c 
                             And id in (select Pergunta__c From Resposta__c Where Relatorio__c =:visit_report.Id)]){
                                 questionMap.put(q.Id, q);
                                 //construir mapas com os respectivos valores de listas
                                 if(recordTypes.get(q.RecordTypeId).Name=='Multi picklist'){
                                     multipicklistvalues.put(q.Id, new List<SelectedValue>());
                                     for(String s : String.valueOf(q.Opcoes_de_lista__c).split('\r\n')){
                                         
                                         SelectedValue value = new SelectedValue();
                                         value.selected = false;
                                         value.value = s;
                                         multipicklistvalues.get(q.Id).add(value);
                                     }
                                 } else if(recordTypes.get(q.RecordTypeId).Name=='Picklist'){
                                     dropDownAnswers.put(q.id, new List<SelectOption>());
                                     dropDownAnswers.get(q.id).add(new SelectOption('','--'));
                                     system.debug(q.id);
                                     for(String s : String.valueOf(q.Opcoes_de_lista__c).split('\r\n')){
                                         dropDownAnswers.get(q.id).add(new SelectOption(s,s));
                                     }
                                 }
                                 
                                 if(q.Momento_de_pergunta__c == 'Durante'){
                                     duringQuestions.add(q);
                                 }else if(q.Momento_de_pergunta__c == 'Apos'){
                                     afterQuestions.add(q);
                                 }
                             }
    }
    
    public Pagereference updateRecord(){
        for(id id : multipicklistvalues.keySet()){
            string v = '';
            for(SelectedValue sv : multipicklistvalues.get(id)){
                if(sv.selected == true){
                    v += sv.value + '\r\n';
                }
                
            }
            answers.get(id).Resposta_em_multipicklist__c= v;
            if (answers.get(id).Resposta_em_multipicklist__c != ''){
                answers.get(id).Resposta_preenchida__c= true;
            }
            else{
                answers.get(id).Resposta_preenchida__c= false;
            }
            
        }

        try{
            
            update answers.values();
            update questionMap.values();
            update visit_report;
            isSucess= true;
            sucessMessage = Label.Questoes_e_relatorio_actualizados + '!';
        }catch(Exception ex){
            errorMessage = 'Something went wrong: ' + (ex.getTypeName() == 'System.DmlException' ? ex.getdmlMessage(0) :
                                                       ' contact the system admin.' + ex.getMessage());
            isSucess= false;
        }
        init();
        
        return null;
    }
    
    public void updateAccount(){
        //Factores Selectivos
        conta.Factores_seletivos__c = buildMultipicklistField(factoresSelectivos);
        
        //Gama de Produtos
        conta.Gama_de_produtos__c = buildMultipicklistField(gamaProdutos);

        //Gama de Produtos
        if(conta.Armazem_proprio__c)
            conta.Principais_produtos_em_stock__c = buildMultipicklistField(principaisProdutos);

        //Gama de Produtos
        conta.Acoes_de_marketing_proprias__c = buildMultipicklistField(marketingProprio);

        try{
            update conta;
            isSucess= true;
            sucessMessage = Label.Conta_actualizada_com_sucesso + '!';
        }catch(Exception ex){
            errorMessage = 'Something went wrong: ' + (ex.getTypeName() == 'System.DmlException' ? ex.getdmlMessage(0) :
                                                                                   ' contact the system admin.' + ex.getMessage());
            isSucess= false;
        }
    }
    
    public String buildMultipicklistField(List<SelectedMultipicklist> lista){
        String result = '';
        for(SelectedMultipicklist sm : lista){
            if(sm.selected){
                result += sm.value + ';';
            }
        }
        return result;
    }
    
    public void getPicklists(){
        
        selectFirstSupplier = getSupplier(Account.X1_Fornecedor__c.getDescribe());
        selectSecondSupplier = getSupplier(Account.X2_Fornecedor__c.getDescribe());
        selectThirdSupplier = getSupplier(Account.X3_Fornecedor__c.getDescribe());
    }

    public List<SelectOption> getSupplier(Schema.DescribeFieldResult fieldResult){
        List<SelectOption> options = new List<SelectOption>();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        system.debug(fieldResult.getName());
        
        options.add(new SelectOption('','--'));
        
        for( Schema.PicklistEntry f : ple){
            system.debug(f.getValue());
            if(!(f.getValue() == conta.X1_Fornecedor__c && fieldResult.getName() != 'X1_Fornecedor__c') &&
               !(f.getValue() == conta.X2_Fornecedor__c && fieldResult.getName() != 'X2_Fornecedor__c') &&
               !(f.getValue() == conta.X3_Fornecedor__c && fieldResult.getName() != 'X3_Fornecedor__c') ||
               f.getValue() == 'Outro'
              ){
                  options.add(new SelectOption(f.getLabel(), f.getValue()));
              }
        }
        
        return options;
    }
    
    public void getSegmentationPicklists(){
        selectFirstSegmentation = getSegmentation(Account.X1_Segmentacao__c.getDescribe());
        selectSecondSegmentation = getSegmentation(Account.X2_Segmentacao__c.getDescribe());
        selectThirdSegmentation = getSegmentation(Account.X3_Segmentacao__c.getDescribe());
    }
    
    public List<SelectOption> getSegmentation(Schema.DescribeFieldResult fieldResult){
        List<SelectOption> options = new List<SelectOption>();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        system.debug(fieldResult.getName());
        
        options.add(new SelectOption('','--'));
        
        for( Schema.PicklistEntry f : ple){
            system.debug(f.getValue());
            if(!(f.getValue() == conta.X1_Segmentacao__c && fieldResult.getName() != 'X1_Segmentacao__c') &&
               !(f.getValue() == conta.X2_Segmentacao__c && fieldResult.getName() != 'X2_Segmentacao__c') &&
               !(f.getValue() == conta.X3_Segmentacao__c && fieldResult.getName() != 'X3_Segmentacao__c')
              ){
                  options.add(new SelectOption(f.getLabel(), f.getValue()));
              }
        }
        
        return options;
    }
    
    public List<SelectedMultipicklist> getMultipicklist(Schema.DescribeFieldResult fieldResult){
        List<SelectedMultipicklist> options = new List<SelectedMultipicklist>();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry f : ple){
            options.add(new SelectedMultipicklist(
                conta.get(fieldResult.getName()) != null ? String.valueOf(conta.get(fieldResult.getName())).contains(f.getValue()): false, f.getValue(), f.getLabel()));
        }
        
        return options;
    }
    
    public Pagereference returnPage(){
        
        Pagereference pg = new Pagereference('/apex/VF_ShowQuestions?id=' + visit_report.Id + (newWindow ? '&param1=true' : ''));
        pg.setRedirect(true);
        return pg;
    }
    
    public class SelectedValue {
        public boolean selected{get;set;}
        public string value{get;set;}
    }
    
    public class SelectedMultipicklist{
        
        public boolean selected{get;set;}
        public string value{get;set;}
        public string label{get;set;}
        
        public SelectedMultipicklist(boolean selected, String value, String label){
            this.selected = selected;
            this.value = value;
            this.label = label;
        }
    }
}