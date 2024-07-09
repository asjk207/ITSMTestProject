import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCaseWithFiles from '@salesforce/apex/CaseController.createCaseWithFiles';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import PRIORITY_FIELD from '@salesforce/schema/Case.Priority';
import PRODUCT_FIELD from '@salesforce/schema/Case.Product__c';
import './caseWithFileUpload.css';

export default class CaseWithFileUpload extends LightningElement {
    @track subject = '';
    @track description = '';
    @track priority = '';
    @track product = '';
    @track priorityOptions = [];
    @track productOptions = [];
    uploadedFiles = [];

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: PRIORITY_FIELD })
    wiredPriorityValues({ error, data }) {
        if (data) {
            this.priorityOptions = data.values;
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading priority picklist values',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: PRODUCT_FIELD })
    wiredProductValues({ error, data }) {
        if (data) {
            this.productOptions = data.values;
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading product picklist values',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        }
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    handleDescriptionChange(event) {
        this.description = event.target.value;
    }

    handlePriorityChange(event) {
        this.priority = event.target.value;
    }

    handleProductChange(event) {
        this.product = event.target.value;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => this.uploadedFiles.push(file.documentId));
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Files uploaded successfully',
                variant: 'success',
            }),
        );
    }

    handleSubmit() {
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (allValid) {
            createCaseWithFiles({ 
                subject: this.subject, 
                description: this.description, 
                priority: this.priority,
                product: this.product,
                contentDocumentIds: this.uploadedFiles 
            })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Case created and files attached successfully',
                            variant: 'success',
                        }),
                    );
                    // Reset form
                    this.subject = '';
                    this.description = '';
                    this.priority = '';
                    this.product = '';
                    this.uploadedFiles = [];
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating case',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                });
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill out all required fields',
                    variant: 'error',
                }),
            );
        }
    }
}
