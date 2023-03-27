import { createElement } from 'lwc';
import UnfilledFieldsDisplay from 'c/unfilledFieldsDisplay';
import getAllQueriedFieldsAndRecordsWithEmptyFields from '@salesforce/apex/FieldUsageScanner.getAllQueriedFieldsAndRecordsWithEmptyFields';

// Mocking imperative Apex method call
jest.mock(
    '@salesforce/apex/FieldUsageScanner.getAllQueriedFieldsAndRecordsWithEmptyFields',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

const MOCK_PAYLOAD = {
        fields: {
            opportunity: {
                amount: 1
            },
            account: {
                name: 2,
                annualrevenue: 3
            },
            contact: {
                name: 4,
                phone: 5
            } 
        },
        records: {
            opportunity: {
                oid1: ['amount'],
                oid2: ['amount'],
                oid3: ['amount']
            },
            account: {
                aid1: ['name', 'annualrevenue'],
                aid2: ['name', 'annualrevenue'],
                aid3: ['name']
            },
            contact: {
                cid1: ['name', 'phone'],
                cid2: ['name'],
                cid3: ['name', 'phone']} 
        }
    };

describe('c-unfilled-fields-display', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    async function flushPromises() {
        return Promise.resolve();
    }

    it('should format and display retrieved object as iterations of lists', async () => {
        getAllQueriedFieldsAndRecordsWithEmptyFields.mockResolvedValue(MOCK_PAYLOAD);

        // Arrange
        const element = createElement('c-unfilled-fields-display', {
            is: UnfilledFieldsDisplay
        });

        // Act
        document.body.appendChild(element);
        const button = element.shadowRoot.querySelector('lightning-button');
        button.click();

        await flushPromises();

        // Assert

        // check <a>
        const links = element.shadowRoot.querySelectorAll('a');
        expect(links.length).toBe(9);
        expect(links[0].textContent).toBe('Record ID: oid1');
        expect(links[1].textContent).toBe('Record ID: oid2');
        expect(links[2].textContent).toBe('Record ID: oid3');
        expect(links[3].textContent).toBe('Record ID: aid1');
        expect(links[4].textContent).toBe('Record ID: aid2');
        expect(links[5].textContent).toBe('Record ID: aid3');
        expect(links[6].textContent).toBe('Record ID: cid1');
        expect(links[7].textContent).toBe('Record ID: cid2');
        expect(links[8].textContent).toBe('Record ID: cid3');
        
        // check <p>
        const fields = element.shadowRoot.querySelectorAll('p:not([id*="introText"])');
        expect(fields[0].textContent).toBe('amount is queried 1 time(s).');
        expect(fields[1].textContent).toBe('amount is queried 1 time(s).');
        expect(fields[2].textContent).toBe('amount is queried 1 time(s).');
        
        expect(fields[3].textContent).toBe('name is queried 2 time(s).');
        expect(fields[4].textContent).toBe('annualrevenue is queried 3 time(s).');
        expect(fields[5].textContent).toBe('name is queried 2 time(s).');
        expect(fields[6].textContent).toBe('annualrevenue is queried 3 time(s).');
        expect(fields[7].textContent).toBe('name is queried 2 time(s).');
        
        expect(fields[8].textContent).toBe('name is queried 4 time(s).');
        expect(fields[9].textContent).toBe('phone is queried 5 time(s).');
        expect(fields[10].textContent).toBe('name is queried 4 time(s).');
        expect(fields[11].textContent).toBe('name is queried 4 time(s).');
        expect(fields[12].textContent).toBe('phone is queried 5 time(s).');
        
        // check <lightning-card>
        const lightningCard = element.shadowRoot.querySelectorAll('lightning-card:not([id*="dialogueCard"])');
        expect(lightningCard[0].title).toBe('opportunity (3)');
        expect(lightningCard[1].title).toBe('account (3)');
        expect(lightningCard[2].title).toBe('contact (3)');
    });
});