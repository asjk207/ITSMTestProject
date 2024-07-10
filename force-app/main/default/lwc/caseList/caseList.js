import { LightningElement, track } from 'lwc';
import getCases from '@salesforce/apex/CaseController.getCases';
import { NavigationMixin } from 'lightning/navigation';

const columns = [
    { label: 'Case Number', fieldName: 'CaseNumber', type: 'text' },
    { label: 'Subject', fieldName: 'caseLink', type: 'url', typeAttributes: { label: { fieldName: 'Subject' }, target: '_blank' } },
    { label: 'Status', fieldName: 'Status', type: 'text' },
    { label: 'Date/Time Modified', fieldName: 'LastModifiedDate', type: 'date', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' } },
    { label: 'Contact Full Name', fieldName: 'ContactName', type: 'text' }
];

export default class CaseList extends NavigationMixin(LightningElement) {
    @track searchQuery = '';
    @track selectedStatus = '';
    @track cases;
    @track error;
    //@track contactId;
    @track status;

    columns = columns;

    statusOptions = [
        { label: 'All', value: '' },
        { label: 'New', value: 'New' },
        { label: 'Closed', value: 'Closed' },
        { label: 'In Progress', value: 'In Progress' },
    ];

    connectedCallback() {
        // URL에서 status를 추출합니다.
        const urlParams = new URLSearchParams(window.location.search);
        this.status = urlParams.get('status');
        this.loadCases();
    }

    /*fetchContactId() {
        getContactId()
            .then(contactId => {
                this.contactId = contactId;
                console.log('ContactId:', this.contactId); // 디버깅
                this.loadCases();
            })
            .catch(error => {
                this.error = error;
                this.contactId = null;
                console.error('Error fetching ContactId:', error); // 디버깅
            });
    }*/

    loadCases() {
        getCases({ status: this.status })
            .then(data => {
                this.cases = data.map(caseRecord => ({
                    ...caseRecord,
                    ContactName: caseRecord.Contact ? caseRecord.Contact.Name : '',
                    caseLink: `/customerservice/s/casedetail?recordId=${caseRecord.Id}`
                }));
                this.error = undefined;
                console.log('Cases loaded:', JSON.stringify(this.cases)); // 디버깅
            })
            .catch(error => {
                this.error = error;
                this.cases = undefined;
                console.error('Error loading cases:', error); // 디버깅
            });
    }

    get filteredCases() {
        let filtered = this.cases;
        if (this.searchQuery) {
            filtered = filtered.filter(caseRecord => caseRecord.Subject.toLowerCase().includes(this.searchQuery.toLowerCase()));
        }
        if (this.selectedStatus) {
            filtered = filtered.filter(caseRecord => caseRecord.Status === this.selectedStatus);
        }
        return filtered;
    }

    handleSearch(event) {
        this.searchQuery = event.target.value;
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }
}