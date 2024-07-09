import { LightningElement, api } from 'lwc';
import getCaseCount from '@salesforce/apex/CaseController.getCaseCount';

export default class CaseCountDisplay extends LightningElement {
    @api status;
    caseCount;
    caseCountClass;
    statusText;

    connectedCallback() {
        this.fetchCaseCount();
        this.setStatusTextAndClass();
    }

    fetchCaseCount() {
        if (this.status) {
            getCaseCount({ status: this.status })
                .then(result => {
                    this.caseCount = result;
                })
                .catch(error => {
                    this.caseCount = 'Error retrieving case count';
                    console.error(error);
                });
        } else {
            this.caseCount = 'Missing required parameters';
        }
    }

    setStatusTextAndClass() {
        switch (this.status) {
            case 'New':
                this.statusText = '접수';
                this.caseCountClass = 'new';
                break;
            case 'Working':
                this.statusText = '진행';
                this.caseCountClass = 'working';
                break;
            case 'Closed':
                this.statusText = '완료';
                this.caseCountClass = 'closed';
                break;
            default:
                this.statusText = 'Unknown';
                this.caseCountClass = '';
                break;
        }
    }

    handleCaseCountClick() {
        const url = `/customerservice/s/my-cases?status=${this.status}`;
        window.location.href = url;
    }
}
