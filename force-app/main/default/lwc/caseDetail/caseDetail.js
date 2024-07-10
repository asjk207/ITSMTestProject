import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getCaseComments from '@salesforce/apex/CaseController.getCaseComments';
import addCaseComment from '@salesforce/apex/CaseController.addCaseComment';
import closeCase from '@salesforce/apex/CaseController.closeCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

const CASE_FIELDS = [
    'Case.CaseNumber',
    'Case.Subject',
    'Case.Status',
    'Case.CreatedDate'
];

export default class CaseDetail extends NavigationMixin(LightningElement) {
    @api recordId;
    @track caseData;
    @track comments;
    @track newComment = '';
    @track error;

    @wire(CurrentPageReference)
    pageRef;

    connectedCallback() {
        // URL에서 recordId를 추출합니다.
        const urlParams = new URLSearchParams(window.location.search);
        this.recordId = urlParams.get('recordId');
        console.log('recordId:', this.recordId); // 디버깅
    }

    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            this.caseData = data;
            console.log('Case data loaded:', JSON.stringify(data)); // 디버깅
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.caseData = undefined;
            console.error('Error loading case data:', JSON.stringify(error)); // 디버깅
        }
    }

    @wire(getCaseComments, { caseId: '$recordId' })
    wiredComments({ error, data }) {
        if (data) {
            this.comments = data;
            console.log('Comments loaded:', JSON.stringify(data)); // 디버깅
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.comments = undefined;
            console.error('Error loading comments:', JSON.stringify(error)); // 디버깅
        }
    }

    get caseId() {
        return this.recordId;
    }

    get isClosed() {
        return this.caseData?.fields?.Status?.value === 'Closed';
    }

    handleCommentChange(event) {
        this.newComment = event.target.value;
    }

    handleAddComment() {
        addCaseComment({ caseId: this.recordId, commentBody: this.newComment })
            .then(result => {
                // Add the new comment to the comments array
                this.comments = [...this.comments, result];
                // Clear the input field
                this.newComment = '';
                // Show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Comment added',
                        variant: 'success',
                    }),
                );
                console.log('Comment added:', JSON.stringify(result)); // 디버깅
            })
            .catch(error => {
                this.error = error;
                // Show error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error adding comment',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
                console.error('Error adding comment:', JSON.stringify(error)); // 디버깅
            });
    }

    handleCloseCase() {
        closeCase({ caseId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Case closed',
                        variant: 'success',
                    }),
                );
                // Fetch the latest case data to reflect the status change
                return refreshApex(this.wiredCase);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error closing case',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }
}