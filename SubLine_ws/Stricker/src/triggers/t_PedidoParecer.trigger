trigger t_PedidoParecer on Pedido_de_parecer__c (after update) {
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            Map<Id, Case> mapCasos = new Map<Id,Case>([Select Id, 
                                                       (Select Id, Pedido_de_recolha_aberto__c , Resposta_final__c, Pedido_de_fotos_aberto__c,Reclamacao__c
                                                        from Pedidos_de_parecer__r)
                                                       from Case 
                                                       Where Id In (Select Reclamacao__c From Pedido_de_parecer__c Where Id In :Trigger.new)]);
            List<Case> updateCases = new List<Case>();
            for(Pedido_de_parecer__c pedido : Trigger.new){
               updateCases.add(UtilClaims.verificarCaso(mapCasos.get(pedido.Reclamacao__c), mapCasos.get(pedido.Reclamacao__c).Pedidos_de_parecer__r));
            }
        }
    }
}