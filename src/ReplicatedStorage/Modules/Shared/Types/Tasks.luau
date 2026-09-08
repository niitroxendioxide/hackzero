
type SubTier = "S" | "A" | "B" | "C" | "X" 

export type TaskType = "Recover" | "Revenge" | "Escort"
export type UUID = string;
export type AgencyTaskMission = {
    Seed: string,
    Type: TaskType,
	Item: string?,
	World: string,
	Level: number,
	Character: string?,
    Rewards: { [SubTier]: {
        {Type: 'Gems' | 'Money' | 'Artifact' | 'Item', Extra: { Name: string }?, Amount: number}
    } }
}

export type StoredAgencyMission = {
    Id: string,
    Completion: {
        Status: boolean,
        RatingObtained: string?,
        Date: number?,
        Claimed: boolean,
    }
}

return nil