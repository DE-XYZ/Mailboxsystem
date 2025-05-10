// Hauptanwendung
const app = Vue.createApp({
    data() {
        return {
            visible: false,
            activeTab: 'inbox',
            sendType: 'letter',
            account: null,
            mails: [],
            inventory: [],
            selectedItems: [],
            viewingMail: false,
            currentMail: null,
            selectingItem: false,
            selectingItemData: null,
            itemQuantity: 1,
            sendForm: {
                recipient: '',
                subject: '',
                content: '',
            },
            locales: {
                ui_title: 'Postal System',
                ui_inbox: 'Inbox',
                ui_send: 'Send',
                ui_account: 'Account',
                ui_create_account: 'Create Account',
                ui_send_letter: 'Send Letter',
                ui_send_package: 'Send Package',
                ui_recipient: 'Recipient',
                ui_subject: 'Subject',
                ui_message: 'Message',
                ui_items: 'Items',
                ui_cost: 'Cost: %s',
                ui_send_btn: 'Send',
                ui_cancel: 'Cancel',
                ui_close: 'Close',
                ui_delete: 'Delete',
                ui_read: 'Read',
                ui_collect: 'Collect',
                ui_from: 'From: %s',
                ui_to: 'To: %s',
                ui_date: 'Date: %s',
                ui_no_mail: 'No mail available',
                ui_your_address: 'Your address: %s',
                ui_create: 'Create',
                no_account: 'You don\'t have a mail account',
                mail_blip: 'Post Office',
                press_to_open: 'Press E to open the post office',
            }
        };
    },
    computed: {
        hasAccount() {
            return this.account !== null;
        }
    },
    methods: {
        // UI-Methoden
        closeUI() {
            this.visible = false;
            fetch('https://postal_system/closeUI', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            });
        },
        
        // Konto-Methoden
        createAccount() {
            fetch('https://postal_system/createAccount', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            });
        },
        
        // Mail-Methoden
        loadMails() {
            fetch('https://postal_system/loadMails', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            })
            .then(response => response.json())
            .then(data => {
                this.mails = data.mails || [];
            });
        },
        
        sendMail() {
            if (!this.sendForm.recipient || !this.sendForm.subject) {
                return;
            }
            
            if (this.sendType === 'letter') {
                fetch('https://postal_system/sendLetter', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        recipient: this.sendForm.recipient,
                        subject: this.sendForm.subject,
                        content: this.sendForm.content
                    })
                });
            } else {
                fetch('https://postal_system/sendPackage', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        recipient: this.sendForm.recipient,
                        subject: this.sendForm.subject,
                        content: this.sendForm.content,
                        items: JSON.stringify(this.selectedItems)
                    })
                });
            }
            
            this.resetForm();
            this.activeTab = 'inbox';
        },
        
        resetForm() {
            this.sendForm = {
                recipient: '',
                subject: '',
                content: ''
            };
            this.selectedItems = [];
        },
        
        viewMail(mail) {
            this.currentMail = mail;
            this.viewingMail = true;
        },
        
        closeMailView() {
            this.viewingMail = false;
            this.currentMail = null;
        },
        
        collectMail(mail) {
            fetch('https://postal_system/collectMail', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    id: mail.id
                })
            });
            
            if (this.viewingMail) {
                this.closeMailView();
            }
        },
        
        // Item-Methoden für Pakete
        loadInventory() {
            fetch('https://postal_system/getInventory', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            })
            .then(response => response.json())
            .then(data => {
                this.inventory = data.inventory || [];
            });
        },
        
        selectItem(item) {
            // Prüfen, ob das Item bereits ausgewählt ist
            const existingIndex = this.selectedItems.findIndex(i => i.name === item.name);
            if (existingIndex !== -1) {
                // Item bereits ausgewählt, Anzahl erhöhen
                const selectedItem = this.selectedItems[existingIndex];
                if (selectedItem.count < item.count) {
                    this.selectingItemData = item;
                    this.itemQuantity = 1;
                    this.selectingItem = true;
                }
            } else {
                // Neues Item auswählen
                this.selectingItemData = item;
                this.itemQuantity = 1;
                this.selectingItem = true;
            }
        },
        
        increaseQuantity() {
            if (this.itemQuantity < this.selectingItemData.count) {
                this.itemQuantity++;
            }
        },
        
        decreaseQuantity() {
            if (this.itemQuantity > 1) {
                this.itemQuantity--;
            }
        },
        
        confirmItemSelection() {
            const existingIndex = this.selectedItems.findIndex(i => i.name === this.selectingItemData.name);
            
            if (existingIndex !== -1) {
                // Item bereits vorhanden, Anzahl aktualisieren
                const currentCount = this.selectedItems[existingIndex].count;
                const availableCount = this.selectingItemData.count;
                
                // Sicherstellen, dass wir nicht mehr als verfügbar hinzufügen
                const newCount = Math.min(currentCount + this.itemQuantity, availableCount);
                this.selectedItems[existingIndex].count = newCount;
            } else {
                // Neues Item hinzufügen
                this.selectedItems.push({
                    name: this.selectingItemData.name,
                    label: this.selectingItemData.label,
                    count: this.itemQuantity
                });
            }
            
            this.cancelItemSelection();
        },
        
        cancelItemSelection() {
            this.selectingItem = false;
            this.selectingItemData = null;
            this.itemQuantity = 1;
        },
        
        removeItem(index) {
            this.selectedItems.splice(index, 1);
        },
        
        calculateCost() {
            if (this.sendType === 'letter') {
                return '$10'; // Briefkosten
            } else {
                // Grundpreis + Gewicht * Multiplikator
                let totalWeight = 0;
                this.selectedItems.forEach(item => {
                    const invItem = this.inventory.find(i => i.name === item.name);
                    if (invItem && invItem.weight) {
                        totalWeight += invItem.weight * item.count;
                    }
                });
                
                return `$${(50 + (totalWeight * 2)).toFixed(2)}`; // Beispiel: Grundpreis $50 + Gewicht * $2
            }
        },
        
        // Hilfsfunktionen
        formatDate(dateString) {
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
        },
        
        parseItems(itemsJson) {
            try {
                return JSON.parse(itemsJson) || [];
            } catch (e) {
                return [];
            }
        }
    },
    watch: {
        activeTab(newTab) {
            if (newTab === 'inbox') {
                this.loadMails();
            } else if (newTab === 'send') {
                this.loadInventory();
            }
        },
        sendType(newType) {
            if (newType === 'package') {
                this.loadInventory();
            }
        }
    },
    mounted() {
        // Event Listener für Nachrichten vom FiveM Client
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            if (data.action === 'open') {
                this.visible = true;
                this.account = data.account;
                
                if (this.account) {
                    this.loadMails();
                }
            } else if (data.action === 'accountCreated') {
                this.account = data.account;
                this.activeTab = 'inbox';
                this.loadMails();
            } else if (data.action === 'mailCollected') {
                // Mail aus Liste entfernen
                this.mails = this.mails.filter(mail => mail.id !== data.id);
            } else if (data.action === 'mailReceived') {
                // Wenn im Posteingang, Mails neu laden
                if (this.activeTab === 'inbox') {
                    this.loadMails();
                }
            }
        });
        
        // ESC-Taste zum Schließen
        document.addEventListener('keyup', (event) => {
            if (event.key === 'Escape' && this.visible) {
                this.closeUI();
            }
        });
    }
}).mount('#app');