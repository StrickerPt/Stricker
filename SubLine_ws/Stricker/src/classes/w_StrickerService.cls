public class w_StrickerService {
	public final static Perfil_Integracao__c profile = Perfil_Integracao__c.getValues('StrickerWSDL');
    public final static String access_key = profile.Access_Key__c;
    public final static String endpoint = profile.Endpoint__c;
    
    public static String auth(){
        
        String token = '';
        
        String body = '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">'
            +'<Body>'
            +'<AuthorizeClient xmlns="'+endpoint+'">'
            +'<access_key>'+ access_key +'</access_key>'
            +'</AuthorizeClient>'
            +'</Body>'
            +'</Envelope>';
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(''+endpoint+'wsdl_server.php');
        req.setHeader('Content-Type','text/xml; charset="utf-8');
        req.setHeader('SOAPAction',''+endpoint+'AuthorizeClient');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody(body);
        HttpResponse res = new HttpResponse();
        
        if(!Test.isRunningTest()){
            res = http.send(req);
        }else{
            body = '<?xml version="1.0" encoding="UTF-8"?>'
                +'<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://wsdl.stricker.pt/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
                +'<SOAP-ENV:Body>'
                +'<ns1:AuthorizeClientResponse>'
                +'<return xsi:type="xsd:string">X8pC4o7Uz</return>'
                +'</ns1:AuthorizeClientResponse>'
                +'</SOAP-ENV:Body>'
                +'</SOAP-ENV:Envelope>';
            res.setBody(body);
            res.setStatusCode(200);
        }
        system.debug(res.getBody());
        if(res.getStatusCode() == 200){
            dom.Document doc = res.getBodyDocument();
            dom.XmlNode root = doc.getRootElement();//xml
            for(Dom.XmlNode xmlbody: root.getChildren()){//Envelope
                for(dom.XmlNode node :xmlbody.getChildren()){//Body
                    for(dom.XmlNode node1 :node.getChildren()){//AuthorizeClientResponse
                        for(dom.XmlNode node2 :node.getChildren()){//return
                            token = node2.getText();
                        }
                    }
                }
            }
        }
        return token;
    }
    
    public static void clearSessions(String token){
        String body = '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">'
            +'<Body>'
            +'<CloseSession xmlns="'+endpoint+'">'
            +'<token>'+ token +'</token>'
            +'</CloseSession>'
            +'</Body>'
            +'</Envelope>';
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(''+endpoint+'wsdl_server.php');
        req.setHeader('Content-Type','text/xml; charset="utf-8');
        req.setHeader('SOAPAction',''+endpoint+'CloseSession');
        req.setMethod('POST');
        req.setBody(body);
        req.setTimeout(120000);
        HttpResponse res = new HttpResponse();
        
        if(!Test.isRunningTest()){
            res = http.send(req);
        }else{
            body = +'<?xml version="1.0" encoding="utf-8"?>';
            res.setBody(body);
            res.setStatusCode(200);
        }
    }
    
    public static WrapperCalculoTransportadora calculaTransporte(String token, String country_iso, String codpostal, String localidade, String total_encomenda,
                                                                 String peso, String volume, String moeda, String paisCliente, String codPostalCliente){
        String result = '';
        String body = '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">'
            +'<Body>'
            +'<calculaTransporte xmlns="'+endpoint+'">'
            +'<token>'+ token +'</token>'
            +'<country_iso>'+ country_iso +'</country_iso>'
            +'<codpostal>'+ codpostal +'</codpostal>'
            +'<localidade>'+ localidade +'</localidade>'
            +'<total_encomenda>'+ total_encomenda +'</total_encomenda>'
            +'<product_data></product_data>'
            +'<peso>'+ peso +'</peso>'
            +'<volume>'+ volume +'</volume>'
            +'<moeda>'+ moeda +'</moeda>'
            +'<paisCliente>'+ paisCliente +'</paisCliente>'
            +'<codPostalCliente>'+ codPostalCliente +'</codPostalCliente>'
            +'</calculaTransporte>'
            +'</Body>'
            +'</Envelope>';
        system.debug(body);
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(''+endpoint+'wsdl_server.php');
        req.setHeader('Content-Type','text/xml; charset="utf-8');
        req.setHeader('SOAPAction',''+endpoint+'calculaTransporte');
        req.setMethod('POST');
        req.setBody(body);
        req.setTimeout(120000);
        HttpResponse res = new HttpResponse();
        
        if(!Test.isRunningTest()){
            res = http.send(req);
        }else{
            body = '<?xml version="1.0" encoding="UTF-8"?>'
                +'<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://wsdl.stricker.pt/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
                +'<SOAP-ENV:Body>'
                +'<ns1:calculaTransporteResponse>'
                +'<return xsi:type="xsd:string">{"CTT":{"valor_transporte":0,"valor_despacho":0,"valor_custo":"3.49","duracao":1,"moeda":"EUR","peso":"12"}}</return>'
                +'</ns1:calculaTransporteResponse>'
                +'</SOAP-ENV:Body>'
                +'</SOAP-ENV:Envelope>';
            res.setBody(body);
            res.setStatusCode(200);
        }
        system.debug(res.getBody());
        if(res.getStatusCode() == 200){
            dom.Document doc = res.getBodyDocument();
            dom.XmlNode root = doc.getRootElement();//xml
            for(Dom.XmlNode xmlbody: root.getChildren()){//Envelope
                for(dom.XmlNode node :xmlbody.getChildren()){//Body
                    for(dom.XmlNode node1 :node.getChildren()){//calculaTransporteResponse
                        for(dom.XmlNode node2 :node.getChildren()){//return
                            result = node2.getText();
                        }
                    }
                }
            }
        }
        return (WrapperCalculoTransportadora) JSON.deserialize(result.replace(' ', '_'), WrapperCalculoTransportadora.class);
    }
}