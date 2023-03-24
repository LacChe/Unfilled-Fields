import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllQueriedFieldsAndRecordsWithEmptyFields from '@salesforce/apex/FieldUsageScanner.getAllQueriedFieldsAndRecordsWithEmptyFields';

export default class UnfilledFieldsDisplay extends NavigationMixin(LightningElement) {

    @track buttonLabel = 'Scan';

    // <sobject name, <field name, use count>>
    @track fields;

    // <sobject name, <record id, list of empty fields>>
    @track records;

    handleStartScanButton(){
        if(this.buttonLabel !== 'Scan') return;
        this.buttonLabel = 'Processing...';
        getAllQueriedFieldsAndRecordsWithEmptyFields()
            .then(result => {
                this.fields = result.fields;
                this.records = result.records;
                this.buttonLabel = 'Scan';

                /*
                console.log('_____fields_', this.fields);
                for (var key in this.fields) {
                    console.log('_____' + key);
                    for (var key2 in this.fields[key]) {
                        console.log('__________' + key2 + ' ' + JSON.stringify(this.fields[key][key2]));
                    }
                }
                console.log('_____records_', this.records);
                for (var key in this.records) {
                    console.log('_____' + key);
                    for (var key2 in this.records[key]) {
                        console.log('__________' + key2 + ' ' + JSON.stringify(this.records[key][key2]));
                    }
                }
                */
               
            })
            .catch(error => {
                this.buttonLabel = 'Scan';
                console.log('error', error);
            });
    }

    get getFields(){
        return this.fields == null ? this.fields : Object.entries(this.fields);
    }

    get getRecords(){
        var sObjList = [];
        var recordList = [];
        var fieldList = [];
        var checkAllProperties = true;
        var sObjKey;
        var recordKey;
        var fieldKey;
        for (sObjKey in this.records) {

            if(checkAllProperties){
                recordList = [];
                for (recordKey in this.records[sObjKey]) {

                if(checkAllProperties){
                        fieldList = [];
                        for (fieldKey of this.records[sObjKey][recordKey]) {
                            fieldList.push(
                                {
                                    key: window.performance.now() + Math.random(), 
                                    value: fieldKey + ' is queried ' + this.fields[sObjKey][fieldKey] + ' time(s).'
                                });
                        }

                        recordList.push({key: recordKey, value: fieldList});
                    }
                }
                sObjList.push({key: sObjKey + ' (' + Object.keys(this.records[sObjKey]).length + ')', value: recordList});
            }
        }
        return sObjList;
    }

    linkToRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                actionName: 'view'
            }
        });
    }
    
}