global class w_InfoProd{

    static webservice DossierReturn updateDossier(Dossier dossier){
        try{
            system.debug(LoggingLevel.INFO, dossier);
            //tratar caracteres extra
            if(dossier.stamp != null) dossier.stamp = dossier.stamp.trim();
            if(dossier.sla != null) dossier.sla = dossier.sla.trim();
            if(dossier.sit_atual != null) dossier.sit_atual = dossier.sit_atual.trim();
            if(dossier.in_prod != null) dossier.in_prod = dossier.in_prod.trim();
            
            //validar se existe campo identificador - stamp
            if(dossier.stamp != '' && dossier.stamp != null){
                List<Opportunity> checkOpp = [Select Id From Opportunity Where Stamp__c = :dossier.stamp];
                //validar se existe dossier registado em salesforce
                if(!checkOpp.isEmpty()){
                    try{
                        
                        //mapear campos para a estrura da tabela
                        Opportunity opp = checkOpp.get(0);
                        system.debug(LoggingLevel.INFO, dossier.data_lim_prod);
                        if(dossier.data_lim_prod != null) opp.Data_limite_de_producao__c = Datetime.valueOf(dossier.data_lim_prod);
                        if(dossier.sla != '' && dossier.sla != null) opp.SLA__c = dossier.sla;
                        if(dossier.in_prod != null && dossier.in_prod != '') opp.Em_producao__c = dossier.in_prod == '1';
                        if(dossier.sit_atual != '' && dossier.sit_atual != null) opp.Situacao_atual_PHC__c = dossier.sit_atual;
                        
                        //atualizar dossier
                        checkRecursive.runOpportunityAfterUpdate = false;
                        update opp;
                        
                        //retorno de valor de sucesso
                        return new DossierReturn('', '0', true);
                    }catch(DMLException ex){
                        //retorno de erro de base de dados
                        return new DossierReturn(ex.getDmlMessage(0), '2', false);
                    }catch(Exception ex){
                        //retorno de erro genérico de dados
                        return new DossierReturn(ex.getMessage(), '3', false);
                    }
                }else{
                    //retorno de dossier não encontrado
                    return new DossierReturn('Stamp do dossier não encontrado', '1', false);
                }
            }else{
                //retorno de stamp não enviado
                return new DossierReturn('Não foi enviado stamp', '1', false);
            } 
        }catch(Exception ex){
            //erro geral
            return new DossierReturn(ex.getMessage(), '4', false);
        }
    }
    
    global class DossierReturn{
        webservice String erro;
        webservice String tipo_erro;
        webservice boolean result;
        
        public DossierReturn(String erro, String tipo_erro, boolean result){
            this.erro = erro;
            this.tipo_erro = tipo_erro;
            this.result = result;
        }
    }
    
    global class Dossier{
        webservice String stamp;
        webservice String data_lim_prod;
        webservice String sla;
        webservice String in_prod;
        webservice String sit_atual;
        
        public Dossier(String stamp, String data_lim_prod, String sla, String in_prod, String sit_atual){
            this.stamp = stamp;
            this.data_lim_prod = data_lim_prod;
            this.sla = sla;
            this.in_prod = in_prod;
            this.sit_atual = sit_atual;
        }
    }
}