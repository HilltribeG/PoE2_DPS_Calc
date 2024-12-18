#SingleInstance Force
#Persistent
CoordMode "Mouse", "Screen"  ; Makes tooltip position relative to screen
CoordMode "ToolTip", "Screen"
SetWorkingDir %A_ScriptDir%

OnClipboardChange("ClipChanged")

ClipChanged(Type) {
    if (Type != 1)  ; if not text
        return
    
    ; Exit if not a weapon stat block
    if !RegExMatch(Clipboard, "m)^Attacks per Second:.+\R-{8,}")
        return
        
    clipboard := RegExReplace(Clipboard, "\r\n", "`n")  ; Normalize line endings
    
    ; Initialize variables
    physical_min := 0
    physical_max := 0
    lightning_min := 0
    lightning_max := 0
    fire_min := 0
    fire_max := 0
    cold_min := 0
    cold_max := 0
    attacks_per_second := 0
    quality_mod := 0
    
	; Parse clipboard text
	Loop, Parse, clipboard, `n
	{
		if RegExMatch(A_LoopField, "(?:\[Physical\] |Physical )Damage: (\d+)-(\d+)", match)
		{
			physical_min := match1
			physical_max := match2
		}
		else if RegExMatch(A_LoopField, "(?:\[ElementalDamage\|Elemental\] |Elemental )Damage:", match)
		{
			; Split by comma and process each element
			elements := StrSplit(A_LoopField, ",")
			for index, element in elements
			{
				if RegExMatch(element, "(\d+)-(\d+)", dmg)
				{
					if (index = 1)
					{
						cold_min := dmg1
						cold_max := dmg2
					}
					else if (index = 2)
					{
						lightning_min := dmg1
						lightning_max := dmg2
					}
					else if (index = 3)
					{
						fire_min := dmg1
						fire_max := dmg2
					}
				}
			}
		}
		else if RegExMatch(A_LoopField, "(?:Adds (\d+) to (\d+) (?:\[(Fire|Lightning|Cold)\|.*?\]|(Fire|Lightning|Cold)) Damage|(?:(Lightning|Fire|Cold)) Damage: (\d+)-(\d+))", dmg)
		{
			if (dmg3 = "Fire" || dmg4 = "Fire" || dmg5 = "Fire")
			{
				fire_min := dmg1 ? dmg1 : dmg6
				fire_max := dmg2 ? dmg2 : dmg7
			}
			else if (dmg3 = "Lightning" || dmg4 = "Lightning" || dmg5 = "Lightning")
			{
				lightning_min := dmg1 ? dmg1 : dmg6
				lightning_max := dmg2 ? dmg2 : dmg7
			}
			else if (dmg3 = "Cold" || dmg4 = "Cold" || dmg5 = "Cold")
			{
				cold_min := dmg1 ? dmg1 : dmg6
				cold_max := dmg2 ? dmg2 : dmg7
			}
		}
		else if RegExMatch(A_LoopField, "Attacks per Second: ([\d.]+)", match)
		{
			attacks_per_second := match1
		}
		else if RegExMatch(A_LoopField, "(?:\[Quality\]:|Quality:) \+(\d+)%", match)
		{
			quality_mod := match1
		}
	}
    
    ; Calculate average damages
    avg_physical := (physical_min + physical_max) / 2
    avg_lightning := (lightning_min + lightning_max) / 2
    avg_fire := (fire_min + fire_max) / 2
    avg_cold := (cold_min + cold_max) / 2
    
    ; Calculate base DPS
    physical_dps := avg_physical * attacks_per_second
    total_elemental_avg := avg_cold + avg_lightning + avg_fire
    elemental_dps := total_elemental_avg * attacks_per_second
    total_dps := physical_dps + elemental_dps
    
    ; Calculate potential increases
    remaining_quality := (quality_mod < 20) ? 20 - quality_mod : 0
    
    ; Calculate rune potential increases
    phys_rune_increase := physical_dps * 0.20  ; 20% physical increase
    
    ; Lightning rune potential (1-20 damage)
    lightning_rune_dps := ((1 + 20) / 2) * attacks_per_second
    
    ; Fire rune potential (7-11 damage)
    fire_rune_dps := ((7 + 11) / 2) * attacks_per_second
    
    ; Cold rune potential (6-10 damage)
    cold_rune_dps := ((6 + 10) / 2) * attacks_per_second
    
    ; Format numbers to 1 decimal place
    physical_dps := Round(physical_dps, 1)
    elemental_dps := Round(elemental_dps, 1)
    total_dps := Round(total_dps, 1)
    phys_rune_increase := Round(phys_rune_increase, 1)
    lightning_rune_dps := Round(lightning_rune_dps, 1)
    fire_rune_dps := Round(fire_rune_dps, 1)
    cold_rune_dps := Round(cold_rune_dps, 1)
    
    ; Debug info
    ; msgText := "  DPS Calculator Results:`n`n"
    ; msgText .= "  Raw Values:`n"
    ; msgText .= "  Physical: " . physical_min . "-" . physical_max . "`n"
    ; msgText .= "  Cold: " . cold_min . "-" . cold_max . "`n"
    ; msgText .= "  Lightning: " . lightning_min . "-" . lightning_max . "`n"
    ; msgText .= "  Fire: " . fire_min . "-" . fire_max . "`n"
    ; msgText .= "  APS: " . attacks_per_second . "`n`n"
    
    msgText .= "`n"
    msgText .= "  Physical DPS: " . physical_dps . "`n"
    msgText .= "  Elemental DPS: " . elemental_dps . "`n"
	msgText .= "_________________________________________________" . "`n"
    msgText .= "  Total DPS: " . total_dps . "`n`n"
    
    if (remaining_quality > 0)
    {
        potential_physical_dps := Round(physical_dps * (1 + (remaining_quality/100)), 1)
        potential_total_dps := Round(potential_physical_dps + elemental_dps, 1)
        
        msgText .= "  Quality Upgrade Potential:`n"
        msgText .= "  Physical DPS at 20% Quality: " . potential_physical_dps . "`n"
		msgText .= "_________________________________________________" . "`n"
        msgText .= "  Total DPS at 20% Quality: " . potential_total_dps . "`n`n"
    }
    
    msgText .= "  Potential Rune DPS Increases:`n"
    msgText .= "  Physical Rune (+20%): +" . phys_rune_increase . "`n"
    msgText .= "  Lightning Rune (1-20): +" . lightning_rune_dps . "`n"
    msgText .= "  Fire Rune (7-11): +" . fire_rune_dps . "`n"
    msgText .= "  Cold Rune (6-10): +" . cold_rune_dps . "`n"
	msgText .= "  `n"
	
    
    ToolTip % msgText
	SetTimer RemoveToolTip, -6000  ; Negative value means run only once
    return

RemoveToolTip:
    ToolTip
return
}
