trigger t_Files on ContentDocument (before delete) {
    if(checkRecursive.runDocs){
        for(ContentDocument doc : Trigger.old){
            doc.addError('You can\'t erase this record.');
        }
    }
}