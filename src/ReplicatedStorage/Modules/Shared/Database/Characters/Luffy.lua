return {
	Display_Name = 'Monk. The Rookie',
	Nickname = 'Rookie',
	Element = 'Physical',
	Role = 'Stun',
	Tier = "Legendary",
	Faction = "Strawhat Pirates",

	IconGlowColor = Color3.fromRGB(237, 113, 113),

	Appearance = {
		Height = 2.95
	},

	--
	Stats = {
		Health = 638,
		Attack = 70,
		Defense = 10,
		Critical_Rate = 10, -- %
		Critical_Damage = 10,
		Penetration = 0,
		Pen_Ratio = 0,
		Daze = 70,
		Speed = 1,
		Energy_Regeneration = 0.5,
		Affliction_Aptitude = 80,
		Affliction_Facility = 10,


		--
		Walk_Speed = 10,
		Jog_Speed = 20,
		Sprint_Speed = 30,
	},

	Level_Stats = {
		Attack = 7.2,
		Health = 113.75,
		Defense = 6.3,
		Daze = 0.4,
	},

	Moveset_Data = {
		['Basic Attack'] = {
			Base = {
				Speed = 1,
				Animation_Speed = 1,
				Cooldown = .02,

				Attack_Data = {
					-- The "?" symbol means it can be there or not.
					-- Movement Moment, Hit time, Endlag, Movement Time?, Movement Strength?, Movement Linear?
					[1] = {0.2, 0.25, .47},
					[2] = {0.217, 0.267, .955, .22, 1.1},
					[2.1] = {0, 0.283,},
					[2.2] = {0, 0.317,},
					[2.3] = {0, 0.35,},
					[2.4] = {0, 0.8,},
					[3] = {0.283, 0.31, .61, .175, 1.1},
					[4] = {0.22, 0.317, .7, .2, 1.1},
				},

				Sizes = {
					[1] = vector.create(6, 4, 12),
					[2] = vector.create(12, 4, 14),
					[2.1] = vector.create(12, 4, 14),
					[2.2] = vector.create(12, 4, 14),
					[2.3] = vector.create(12, 4, 14),
					[2.4] = vector.create(8, 4, 16),
					[3] = vector.create(8, 4, 16),
					[4] = vector.create(6, 4, 24),
				},

				Damages = {
					[1] = 57,
					[2] = 27,
					[2.1] = 45,
					[2.2] = 41,
					[2.3] = 31,
					[2.4] = 102,
					[3] = 111,
					[4] = 100,
				},

				Dazes = {
					[1] = 71,
					[2] = 55,
					[2.1] = 45,
					[2.2] = 45,
					[2.3] = 55,
					[2.4] = 61,
					[3] = 99,
					[4] = 102,
				},

				Hit = {
					Damage = 1,
					Daze = 1,
					Affliction_Buildup = 10,
					Stun = 0.45,
					Affliction = "Physical",
					HitType = "Blunt",
					Knockback = {
						vector.create(0, 0, 1),
						7,
						.1
					},
				},
			}
		},

		['Special'] = {
			Base = {
				Attack_State_Time = 0.55,
				Speed = 1,
				Animation_Speed = 1,
				Required_Energy = 25,

				Hit = {
					Damage = 127,
					HitType = "Blunt",
					Affliction = "Physical",
					Affliction_Buildup = 10,
					Stun = 0.55,
					Daze = 85,
					Knockback = {
						vector.create(0, 0, 1),
						17,
						0.2
					},
				},
			},
			Upgrade = {
				Hit = {
					Damage = 2,
					Daze = 1,
				},
			},
		},

		['EX Special'] = {
			Base = {
				Attack_State_Time = 0.61,
				Speed = 1,
				Animation_Speed = 1,
				Required_Energy = 25,

				Hit = {
					Damage = 280,
					HitType = "Blunt",
					Affliction = "Physical",
					Affliction_Buildup = 10,
					Stun = 0.55,
					Daze = 85,
					Knockback = {
						vector.create(0, 0, 1),
						32,
						0.3
					},
				},
			},
			Upgrade = {
				Hit = {
					Damage = 2,
					Daze = 1,
				},
			},
		},

		-- Gomu Gomu no Axe: wind up, then one big smash a few studs in front.
		['Dodge Counter'] = {
			Base = {
				Cooldown = 0.5,
				Range = 75,
				Attack_State_Time = 0.95,
				Speed = 1,
				Animation_Speed = 1,

				Smash_Time = 0.55,
				Smash_Offset = vector.create(0, 0, -3),
				Smash_Size = vector.create(14, 8, 14),

				Hit = {
					Damage = 310,
					HitType = "Blunt",
					Affliction = "Physical",
					Affliction_Buildup = 35,
					Stun = 0.7,
					Daze = 140,
					Knockback = {
						vector.create(0, 0, 1),
						20,
						0.25
					},
				},
			},
			Upgrade = {
				Hit = {
					Damage = 3,
					Daze = 1,
				},
			},
		},

		-- Gomu Gomu no Rocket: pull back, launch forward, carry whoever gets hit, release at the end.
		['Quick Assist'] = {
			Base = {
				Cooldown = 1,
				Range = 75,
				Attack_State_Time = 1.1,
				Speed = 1,
				Animation_Speed = 1,

				Pull_Time = 0.3,
				Pull_Power = -0.5,
				Launch_Time = 0.4,
				Launch_Duration = 0.4,
				Launch_Power = 3,

				Hitbox_Size = vector.create(8, 6, 8),
				Hitbox_Offset = vector.create(0, 0, -4),
				Carry_Offset = CFrame.new(0, 0, -3.5),

				Hit = {
					Damage = 140,
					HitType = "Blunt",
					Affliction = "Physical",
					Affliction_Buildup = 15,
					Stun = 0.6,
					Daze = 60,
				},

				Release_Hit = {
					Damage = 190,
					HitType = "Blunt",
					Affliction = "Physical",
					Affliction_Buildup = 20,
					Stun = 0.6,
					Daze = 80,
					Knockback = {
						vector.create(0, 0, 1),
						28,
						0.3
					},
				},
			},
			Upgrade = {
				Hit = {
					Damage = 1,
					Daze = 1,
				},
				Release_Hit = {
					Damage = 2,
					Daze = 1,
				},
			},
		},
	},

	Ascension_Data = {
		[1] = {
			Description = 'Luffy ascension 1',
		},

		[2] = {
			Description = 'Luffy ascension 2',
		},

		[3] = {
			Description = 'Luffy ascension 3',
		},

		[4] = {
			Description = 'Luffy ascension 4',
		},

		[5] = {
			Description = 'Luffy ascension 5',
		},

		[6] = {
			Description = 'Luffy ascension 6',
		},
	}
}