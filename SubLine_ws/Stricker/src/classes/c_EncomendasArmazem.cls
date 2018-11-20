public class c_EncomendasArmazem {
    public Map<Id, OrderItem> linhas {get;set;}
    public Map<Id, OrderItem> linhasDevolucao {get;set;}
    public String pickedLine {get;set;}
    public String pickedLineDevolucao {get;set;}
    public OrderItem dummyLine {get;set;}
    public OrderItem dummyLineRecolha {get;set;}
    public String hora {get;set;}
    public String minuto {get;set;}
    public List<SelectOption> allHours {get;set;}
    public List<SelectOption> allMinutes {get;set;}
    public c_EncomendasArmazem(){
        buildLinhas();
        
        dummyLine = new OrderItem(Data_de_emissao_do_documento_financeiro__c = System.today());
        dummyLineRecolha = new OrderItem(Data_de_emissao_do_documento_financeiro__c = System.today());
        hora = String.valueOf(system.now().hour());
        allHours = new List<SelectOption>();
        for(Integer i = 0; i < 24 ; i++){
            allHours.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
        }

        minuto = String.valueOf(system.now().minute());
        allMinutes = new List<SelectOption>();
        for(Integer i = 0; i < 60 ; i++){
            allMinutes.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
        }
        for(OrderItem item : linhas.values()){
            Decimal temp = 0;
            Set<String> departs = new Set<String>();
            for(Pedido_de_parecer__c pedido: item.Pedidos_de_parecer__r){
                if(temp < pedido.Quantidade_a_recolher__c){
                    temp = pedido.Quantidade_a_recolher__c;
                }
                departs.add(pedido.Departamento__c);
            }
            item.Quantidade_recebida_na_recolha__c = temp;
            boolean isFirst = true;
            for(String dep : departs){
                if(isFirst){
                    item.Recolha_pedida_por__c = dep;
                }else{
                    item.Recolha_pedida_por__c += ';' + dep;
                }
            }
        }
        //produto, quantidade a recolher, tracking number, departamento da mercadoria e quem pediu a mercadoria
        //Data de chegada de recolha, Local_de_armazenamento_da_recolha, Quantidade_recebida_na_recolha, Recolha_recebida_por
    }
    
    public void buildLinhas(){
        linhas = new Map<Id, OrderItem>([Select id, referencia_sku__c, Quantidade_recebida_na_recolha__c,Tracking_Number_de_recolha__c,Destino_de_Mercadoria__c,
                                         Recolha_pedida_por__c,Data_de_chegada_de_recolha__c,
                                         (Select Id,Quantidade_a_recolher__c, Departamento__c 
                                          From Pedidos_de_parecer__r 
                                          Where Pedido_de_recolha__c = true
                                          and Quantidade_a_recolher__c > 0)
                                         from OrderItem 
                                         Where Tracking_Number_de_recolha__c != null
                                         And id In (Select Produto_do_pedido__c 
                                                    From Pedido_de_parecer__c 
                                                    Where Pedido_de_recolha__c = true
                                                    and Quantidade_a_recolher__c > 0)
                                         And Data_de_chegada_de_recolha__c = null]);
        
        linhasDevolucao = new Map<Id, OrderItem>([Select id, referencia_sku__c, Quantidade_recebida_na_devolucao__c,Tracking_Number_de_devolucao__c,Destino_de_Mercadoria__c,
                                                  devolucao_pedida_por__c,Data_de_chegada_de_devolucao__c,Local_de_armazenamento_da_devolucao__c,Devolucao_recebida_por__c 
                                                  from OrderItem 
                                                  Where Tracking_Number_de_devolucao__c != null
                                                  And Data_de_chegada_de_devolucao__c = null]);
    }
    
    public void updateLine(){
        OrderItem item = linhas.containsKey(pickedLine) ? linhas.get(pickedLine) : null;
        
        if(item != null){
            item.Data_de_chegada_de_recolha__c = Datetime.newInstance(dummyLine.Data_de_emissao_do_documento_financeiro__c, 
                                                                      Time.newInstance(Integer.valueOf(hora), Integer.valueOf(minuto), 0, 0));
        }else{
            item = linhasDevolucao.containsKey(pickedLineDevolucao) ? linhasDevolucao.get(pickedLineDevolucao) : null;
            if(item != null){
                item.Data_de_chegada_de_devolucao__c = Datetime.newInstance(dummyLine.Data_de_emissao_do_documento_financeiro__c, 
                                                                          Time.newInstance(Integer.valueOf(hora), Integer.valueOf(minuto), 0, 0));
            }
        }
        update item;
        buildLinhas();
        pickedLine = '';
        pickedLineDevolucao = '';
    }
    
    public void dummy(){}
}