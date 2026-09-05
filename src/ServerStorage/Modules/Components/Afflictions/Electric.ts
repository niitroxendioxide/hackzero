import "@rbxts/types"

class ElectricService {
    is_active: boolean;
    
    constructor() {
        this.is_active = true;
    }   

    private IsActive(): boolean {
        return this.is_active
    }
};

export = () => {

};
