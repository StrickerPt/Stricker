public class IntegratorMoradas {
          public static wsdl_Moradas.MoradasPHCSoap servMoradas = new wsdl_Moradas.MoradasPHCSoap();
    
    
    // 2018/05/09 
    @future(callout=true)
    public static void moradaClienteUpsert(Set<Id> objectsId){
        checkRecursive.runMoradaCliente = false;
        
        
        
        List<Morada_de_entrega__c> moradas = getMoradas(objectsId);
        //servMoradas.endpoint_x = 'http://93.108.232.59:5006/MoradasPHC.asmx';
        doWorkMoradasUpsert(moradas);
        update moradas;
    }
    
    public static List<Morada_de_entrega__c> getMoradas(Set<Id> objectsId){
        String query = 'SELECT '+Integrator.queryBuilder('Morada_de_Entrega__c') + ', Id, Conta__r.Name, Conta__r.Numero_de_cliente__c';
        query += ' FROM Morada_de_entrega__c WHERE id IN :objectsId';
        
        return Database.query(query);
    }
    
    public static void doWorkMoradasUpsert(List<Morada_de_entrega__c> moradas){
        Map<String, User> usersMap = new Map<String, User>([Select id, Codigo_de_utilizador__c, IsActive, Alias from User]);
        
        Integer i = 0;
        for(Morada_de_entrega__c cadaMorada : moradas){
            if(i < 100){ 				
                
                wsdl_Moradas.MoradaClientePHC morada = new wsdl_Moradas.MoradaClientePHC();
                
                morada.numCliente = cadaMorada.Conta__r.Numero_de_cliente__c.isNumeric() ? Integer.valueOf(cadaMorada.Conta__r.Numero_de_cliente__c) : 0;
                morada.Nome_da_empresa_xc = cadaMorada.Nome_da_empresa__c != null ? cadaMorada.Nome_da_empresa__c : '';
                
                morada.MSEQ_xc = cadaMorada.MSEQ__c != null ? String.valueOf(cadaMorada.MSEQ__c) : null;
                morada.Telefone_logistico_xc = cadaMorada.Telefone_logistico__c != null ? cadaMorada.Telefone_logistico__c : '';
                morada.Morada_de_entrega_xc = cadaMorada.Morada_de_entrega__c != null ? cadaMorada.Morada_de_entrega__c : '';
                morada.Localidade_xc = cadaMorada.Localidade__c != null ? cadaMorada.Localidade__c : '';               
                morada.Codigo_postal_xc = cadaMorada.Codigo_postal__c != null ? cadaMorada.Codigo_postal__c : '';               			 
                morada.Pais_xc = cadaMorada.Pais__c != null ? cadaMorada.Pais__c : null;       
                morada.Ao_cuidado_de_xc = cadaMorada.Ao_cuidado_de__c != null ? cadaMorada.Ao_cuidado_de__c : '';                  	  
                
                morada.utilizadorLogado = usersMap.containsKey(UserInfo.getUserId()) ? usersMap.get(UserInfo.getUserId()).Alias : '';
                morada.IDSF = cadaMorada.Id != null ? cadaMorada.Id : '';
                morada.Stamp_xc = cadaMorada.Stamp__c != null ? cadaMorada.Stamp__c : '';
                
                wsdl_Moradas.stampUpSet  resposta; 
                resposta = servMoradas.upSert_x(morada);
                
                if(resposta.erros > 0){
                    cadaMorada.Erros__c = 'Erro: ' + resposta.erros + ';\r\n' + resposta.errorMessage;
                    UtilClaims.sendEmailFailure('Falha upsert morada', 'Morada de cliente: ' + cadaMorada.Id + '\r\n Erro: ' + resposta.errorMessage);
                }else{
                    cadaMorada.Stamp__c = resposta.stamp;
                }
                i++;
            }else break;
        }
    }
    
    
    // 2018/05/09 
    @future(callout=true)
    public static void MoradaClienteDelete(String objectsId){
        List<IntegratorMoradas.DeleteMoradaCliente> lista = (List<IntegratorMoradas.DeleteMoradaCliente>) JSON.deserialize(objectsId, 
                                                                                                                List<IntegratorMoradas.DeleteMoradaCliente>.class);
        Integer i = 0;
        for(IntegratorMoradas.DeleteMoradaCliente cadaMorada : lista){
            if(i < 100){
                wsdl_Moradas.stampUpSet  resposta;
                resposta= servMoradas.delete_x(cadaMorada.stamp, cadaMorada.sfid);
                system.debug(resposta);
                i++;
            }else break;
        }
    }
    
    
    	 public class DeleteMoradaCliente{
                public String stamp;
                public String sfid;
        
        public DeleteMoradaCliente(String stamp,String sfid){
                this.stamp = stamp;
                this.sfid = sfid;
        }
	 }
    

}