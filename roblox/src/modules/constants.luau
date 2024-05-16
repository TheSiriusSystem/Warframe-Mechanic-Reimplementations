--!strict
local Const = {}

function Const.customEnum(values: {string}, startAsUnfrozen: boolean?): {[string]: number}
	local compiledEnum: {[string]: number} = {}
	for i = 1, #values do
		compiledEnum[values[i]] = bit32.lshift(1, i - 1)
	end
	if startAsUnfrozen == true then
		return compiledEnum
	end
	return table.freeze(compiledEnum)
end

Const.UIHealthBarFlags = Const.customEnum({
	"FLIP", -- Flips bar draw order.
	"NO_OBJECT_HEALTH_COLOR", -- Do not change the Health bar color if the actor's Health class is Object.
	"NO_ARMORED_HEALTH_COLOR", -- Do not change the Health bar color if the actor has Armor.
	"NO_DAMAGE_EFFECT", -- Do not draw a Frame at the end of the Health and Shield bars on damage taken.
	"USE_OVERGUARD_BORDER", -- Draws the Overguard bar as a border.
}, true)
Const.UIHealthBarFlags.PLAYER_BAR = Const.UIHealthBarFlags.FLIP + Const.UIHealthBarFlags.NO_OBJECT_HEALTH_COLOR + Const.UIHealthBarFlags.NO_ARMORED_HEALTH_COLOR
Const.UIHealthBarFlags = table.freeze(Const.UIHealthBarFlags)
Const.DamageFlags = Const.customEnum({
	"EXPLOSION", -- The attack will be marked as splash damage from an explosion.
	"IGNORE_HEALTH_CLASS", -- The attack won't apply taken damage modifiers defined by the victim's Health class.
	"IGNORE_SHIELD_CLASS", -- The attack won't apply taken damage modifiers defined by the victim's Shield class.
	"IGNORE_SHIELD", -- The attack ignores the victim's Shield. Does nothing if the victim has SuperShield set to true.
	"IGNORE_ARMOR", -- The attack ignores damage reduction from the victim's Armor.
	"IGNORE_OVERGUARD", -- The attack ignores the victim's Overguard.
	"IGNORE_INVULNERABLE", -- The attack ignores the victim's ForceField. 
})

Const.TAG_ACTOR = "Actor"
Const.DAMAGE_TYPES = {
	Impact = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = -0.25,
			Machinery = 0.25,
			Flesh = -0.25,
			Robotic = 0.0,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = 0.0,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.5,
			ProtoShield = 0.15,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.0,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Puncture = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.0,
			Flesh = 0.0,
			Robotic = 0.25,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = 0.0,
			IndifferentFacade = 0.25,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = -0.2,
			ProtoShield = -0.5,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.5,
			AlloyArmor = 0.15,
			InfestedSinew = 0.25,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Slash = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.25,
			Machinery = 0.0,
			Flesh = 0.25,
			Robotic = -0.25,
			Infested = 0.25,
			InfestedFlesh = 0.5,
			Fossilized = 0.15,
			IndifferentFacade = -0.5,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = -0.15,
			AlloyArmor = -0.5,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Heat = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.25,
			Machinery = 0.0,
			Flesh = 0.0,
			Robotic = 0.0,
			Infested = 0.25,
			InfestedFlesh = 0.5,
			Fossilized = 0.0,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = -0.5,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.0,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Cold = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.0,
			Flesh = 0.0,
			Robotic = 0.0,
			Infested = 0.0,
			InfestedFlesh = -0.5,
			Fossilized = -0.25,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.5,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.25,
			InfestedSinew = 0.25,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Electricity = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.5,
			Flesh = 0.0,
			Robotic = 0.5,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = 0.0,
			IndifferentFacade = 0.25,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = -0.5,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Toxin = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = -0.25,
			Flesh = 0.5,
			Robotic = -0.25,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = -0.5,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = 0.25,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.0,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = true,
		IgnoreArmor = false,
	},
	Blast = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.75,
			Flesh = 0.0,
			Robotic = 0.0,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = 0.5,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = -0.25,
			AlloyArmor = 0.0,
			InfestedSinew = -0.5,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Corrosive = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.0,
			Flesh = 0.0,
			Robotic = 0.0,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = 0.75,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = -0.5,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.75,
			AlloyArmor = 0.0,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Gas = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = -0.5,
			Machinery = 0.0,
			Flesh = -0.25,
			Robotic = 0.0,
			Infested = 0.75,
			InfestedFlesh = 0.5,
			Fossilized = 0.0,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.0,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Magnetic = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.0,
			Flesh = 0.0,
			Robotic = 0.0,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = 0.0,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.75,
			ProtoShield = 0.75,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = -0.5,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Radiation = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.0,
			Flesh = 0.0,
			Robotic = 0.25,
			Infested = -0.5,
			InfestedFlesh = 0.0,
			Fossilized = -0.75,
			IndifferentFacade = 0.75,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = -0.25,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.75,
			InfestedSinew = 0.5,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Viral = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.75,
			Machinery = -0.25,
			Flesh = 0.5,
			Robotic = 0.0,
			Infested = -0.5,
			InfestedFlesh = 0.0,
			Fossilized = 0.0,
			IndifferentFacade = -0.5,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.0,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	Tau = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.0,
			Flesh = 0.0,
			Robotic = 0.0,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = 0.0,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.0,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
	True = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.0,
			Flesh = 0.0,
			Robotic = 0.0,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = 0.0,
			IndifferentFacade = 0.0,
			Object = 0.0,
		},
		Shield = {
			TennoShield = 0.0,
			Shield = 0.0,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.0,
			InfestedSinew = 0.0,
		},
		Overguard = 0.0,
		IgnoreShield = false,
		IgnoreArmor = true,
	},
	Void = {
		Health = {
			TennoFlesh = 0.0,
			ClonedFlesh = 0.0,
			Machinery = 0.0,
			Flesh = 0.0,
			Robotic = 0.0,
			Infested = 0.0,
			InfestedFlesh = 0.0,
			Fossilized = 0.0,
			IndifferentFacade = 0.25,
			Object = 0.0,
		},
		Shield = {
			TennoShield = -0.5,
			Shield = 0.0,
			ProtoShield = 0.0,
		},
		Armor = {
			TennoArmor = 0.0,
			FerriteArmor = 0.0,
			AlloyArmor = 0.0,
			InfestedSinew = 0.0,
		},
		Overguard = 0.5,
		IgnoreShield = false,
		IgnoreArmor = false,
	},
}
Const.BAR_COLOR_HEALTH_UNARMORED = Color3.fromHex("cc2a28")
Const.BAR_COLOR_HEALTH_ARMORED = Color3.fromHex("e0a635")
Const.BAR_COLOR_HEALTH_OBJECT = Color3.fromHex("6dada7")
Const.BAR_COLOR_HEALTH_INVULNERABLE = Color3.fromHex("585858")
Const.BAR_COLOR_SHIELD = Color3.fromHex("01d8ff")
Const.BAR_COLOR_OVERSHIELD = Color3.fromHex("b201fe")
Const.BAR_COLOR_SHIELD_INVULNERABLE = Color3.fromHex("9c9c9a")
Const.BAR_COLOR_OVERGUARD_FILLED = Color3.fromRGB(85, 255, 255)
Const.BAR_COLOR_OVERGUARD_UNFILLED = Color3.fromRGB(163, 162, 165)

return table.freeze(Const)