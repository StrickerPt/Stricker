@RestResource(urlMapping='/token')
global class rest_SiteToken {
  
    @HttpPost
    global static String doPost(String token, String no, String ip, Integer duration, String retUrl) {
        system.debug(token);
        system.debug(no);
        system.debug(ip);
        system.debug(duration);
        system.debug(retUrl);
        Token_Site__c newtoken = new Token_Site__c();
        newtoken.Data_de_entrada__c = System.now();
        newToken.Duracao__c = duration;
        newToken.Ip__c = ip;
        Newtoken.Numero_de_cliente__c = no;
        newToken.Token__c = token;
        newToken.Data_de_validade__c = newtoken.Data_de_entrada__c.addSeconds(duration);
        newtoken.Endereco_de_retorno__c = retUrl;
        insert newToken;
        
        return JSON.serialize(newToken);
    }
}