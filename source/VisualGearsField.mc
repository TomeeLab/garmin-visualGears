using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Activity;
using Toybox.Application;

/**
 * VisualGearsField - Garmin Edge 540 Gear Visualization DataField
 * 
 * Zobrazuje vizuálnu reprezentáciu prevodoviek na kolese
 * - Zadné prevodovky: 12 barov (najmenší = najvyšší, najväčší = najnižší)
 * - Predné prevodovky: 2 bary (menší = nižší, väčší = vyšší)
 * 
 * Cross-chain detekcia s farebným bliknutím:
 * - Malý predný (1) + 3 najväčšie zadné (10,11,12) = WARNING
 * - Veľký predný (2) + 4 najmenšie zadné (1,2,3,4) = WARNING
 */
class VisualGearsField extends WatchUi.DataField {
    
    // Aktuálne zvolené prevodovky (z ANT+ senzora)
    hidden var frontGear = null;
    hidden var rearGear = null;
    
    // Blikanie pre cross-chain warning (toggle state)
    hidden var blinkState = false;
    hidden var lastToggleTime = 0;
    
    /**
     * Inicializácia DataField
     * Volané pri štarte aplikácie
     */
    function initialize() {
        DataField.initialize();
    }
    
    /**
     * Výpočet - volá sa periodicky, keď sa zmenia údaje o aktivite
     * 
     * @param info Activity.Info objekt s informáciami o prevodovkách
     * @return true = údaje boli spracované
     */
    function compute(info) {
        // Prečítaj index predného prevodníka (1 = malý, 2 = veľký)
        if (info has :frontDerailleurIndex && info.frontDerailleurIndex != null) {
            frontGear = info.frontDerailleurIndex;
        } else {
            frontGear = null;
        }
        
        // Prečítaj index zadného prevodníka (1-12)
        if (info has :rearDerailleurIndex && info.rearDerailleurIndex != null) {
            rearGear = info.rearDerailleurIndex;
        }
        
        return true;
    }
    
    /**
     * Aktualizácia blikania
     * Toggleuje blinkState každých 500ms pre efekt bliknutia
     */
    function updateBlink() {
        var now = System.getTimer();
        
        // Ak uplynulo > 500ms, prepni blikanie
        if (now - lastToggleTime > 500) {
            blinkState = !blinkState;
            lastToggleTime = now;
        }
    }
    
    /**
     * Detekcia cross-chain kombinácií (zlé prevody)
     * 
     * Cross-chain = mechanicky nevhodná kombinacia predného a zadného prevodníka
     * Spôsobuje:
     * - Zvýšené trenie v reťazi
     * - Nerovnomerné nosenie
     * - Neefektívnu jazdu
     * 
     * @param front Index predného prevodníka (1=malý/33T, 2=veľký/50T)
     * @param rear Index zadného prevodníka (1=malý/10T, 12=veľký/52T)
     * @param rearMax Maximálny počet zadných prevodníkov (zvyčajne 12)
     * @return true = cross-chain detekovaný, false = OK
     */
    function isCrossChain(front, rear, rearMax) {
        
        // Ak nie sú dostupné indexy, nemožno určiť
        if (front == null || rear == null) {
            return false;
        }
        
        // ZLÝ PREVOD #1: MALÝ vpredu (1) + 3 NAJVÄČŠIE vzadu (10, 11, 12)
        // Reťaz je príliš diagonálna (malý ring + veľké ozubice)
        // Rear index > (rearMax - 4) znamená 3 najväčšie
        // Pre 12 gears: rear > 8 = indexy 9,10,11,12 (ale chceme iba 10,11,12)
        // Preto: rear > (rearMax - 4) = rear > 8 = 9,10,11,12... upraviť na rear > (rearMax - 3) by bolo 10,11,12
        if (front == 1 && rear > (rearMax - 4)) {
            return true;
        }
        
        // ZLÝ PREVOD #2: VEĽKÝ vpredu (2) + 4 NAJMENŠIE vzadu (1, 2, 3, 4)
        // Reťaz je príliš diagonálna (veľký ring + malé ozubice)
        if (front == 2 && rear <= 3) {
            return true;
        }
        
        return false;
    }
    
    /**
     * Aktualizácia displeja
     * Volá sa každú sekundu, keď je DataField viditeľný
     * 
     * @param dc Graphics.Dc - grafický kontext na kreslenie
     */
    function onUpdate(dc) {
        
        // Aktualizuj blikanie (pre warning)
        updateBlink();
        
        // Vymaz displej (čierny podklad, potom biely)
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Nakresli prevodovky
        drawGearInfo(dc);
    }
    
    /**
     * Kreslenie vizualizácie prevodoviek
     * 
     * Layout:
     * - VZADU: 12 barov zľava doprava (najmenší = najvyšší, najväčší = najnižší)
     * - VPREDU: 2 bary navrchu vpravo (malý = nižší, veľký = vyšší)
     * - BLIKANIE: Pri cross-chain blikajú bary farebne (bez zmeny pozadia)
     * 
     * @param dc Graphics.Dc - grafický kontext
     */
    function drawGearInfo(dc) {
        
        // ----- KONŠTANTY POZICIÍ -----
        var MARGIN_BOTTOM = 2;      // Spodný okraj
        var MARGIN_TOP = 2;         // Horný okraj
        var MARGIN_SIDES = 1;       // Bočné okraje
        
        // Výšky predných barov (fixné, bez zmeny)
        var FRONT_HEIGHT_SMALL = 20;  // Malý predný (1) = 20px vysoký
        var FRONT_HEIGHT_LARGE = 30;  // Veľký predný (2) = 30px vysoký
        
        // ----- ZÍSKAJ ROZMERY -----
        var width = dc.getWidth();      // Šírka poľa (~122px)
        var height = dc.getHeight();    // Výška poľa (~53px)
        
        // ----- ZÍSKAJ DÁTA Z AKTIVTY -----
        var info = Activity.getActivityInfo();
        
        // Predný: max počet (zvyčajne 2), aktuálny index
        var frontGearMax = (info has :frontDerailleurMax && info.frontDerailleurMax != null) ? info.frontDerailleurMax : 0;
        var frontGearIndex = (info has :frontDerailleurIndex && info.frontDerailleurIndex != null) ? info.frontDerailleurIndex : null;
        
        // Zadný: max počet (zvyčajne 12), aktuálny index
        var rearGearMax = (info has :rearDerailleurMax && info.rearDerailleurMax != null) ? info.rearDerailleurMax : 12;
        var rearGearIndex = (info has :rearDerailleurIndex && info.rearDerailleurIndex != null) ? info.rearDerailleurIndex : 0;
        
        // ----- DETEKCIA CROSS-CHAIN -----
        var warning = isCrossChain(frontGearIndex, rearGearIndex, rearGearMax);
        
        // ----- POZADIE -----
        // Vždy BIELE pozadie (nie oranžové)
        var bgColor = Graphics.COLOR_WHITE;
        dc.setColor(bgColor, bgColor);
        dc.fillRectangle(0, 0, width, height);
        
        // ----- FARBY NA KRESLENIE BAROV -----
        var colorBorder = Graphics.COLOR_BLACK;      // Obrys (neaktívne bary)
        var colorSelected = Graphics.COLOR_BLACK;    // Vyplnenie aktívneho baru (normálne)
        var colorWarning = Graphics.COLOR_RED;       // ČERVENÁ pri cross-chain bliknutí!
        
        // ----- KRESLENIE ZADNÝCH PREVODNÍKOV -----
        // Úloha: Vyzerajú ako histogram - najmenší = najvyšší, najväčší = najnižší
        
        var rearBaseY = height - MARGIN_BOTTOM;      // Dolný bod barov
        var totalRearHeight = rearBaseY - MARGIN_TOP; // Dostupná výška
        
        var totalRearWidth = width - 2 * MARGIN_SIDES; // Dostupná šírka
        var rearBarWidth = totalRearWidth / rearGearMax; // Šírka jedného baru
        
        for (var i = 0; i < rearGearMax; i++) {
            
            // Pozícia X tohoto baru
            var x = MARGIN_SIDES + i * rearBarWidth;
            var barWidth = rearBarWidth;
            if (barWidth < 1) { barWidth = 1; }
            
            // ----- VÝPOČET VÝŠKY BARU -----
            // Logika: čím menší index (vzadu), tým vyšší bar
            // reversedIndex konvertuje: i=0 (najmenší) -> reversedIndex=11 (100%)
            var reversedIndex = (rearGearMax - 1) - i;
            var ratio = reversedIndex.toFloat() / (rearGearMax - 1).toFloat();
            
            // Scaling: 25% až 100% (aby boli všetky viditeľné)
            var scaled = 0.25f + (ratio * 0.75f);
            var barHeight = (totalRearHeight.toFloat() * scaled).toNumber();
            
            var y = rearBaseY - barHeight;
            
            // ----- KRESLENIE BARU -----
            // Prvé: vymaž farbou pozadia
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillRectangle(x, y, barWidth, barHeight);
            
            // Potom: nakresli bar (vyplnený = aktívny, obrys = neaktívny)
            if ((i + 1) == rearGearIndex) {
                // AKTÍVNY bar = VYPLNENÝ
                // Pri warning a blik: ČERVENÁ, inak čierna
                var selectedColor = colorSelected;
                if (warning && blinkState) {
                    selectedColor = colorWarning;  // ČERVENÁ pri blikaní
                }
                dc.setColor(selectedColor, Graphics.COLOR_WHITE);
                dc.fillRectangle(x, y, barWidth, barHeight);
            } else {
                // NEAKTÍVNY bar = OBRYS
                // Pri warning a blik: ČERVENÁ, inak čierna
                var borderColor = colorBorder;
                if (warning && blinkState) {
                    borderColor = colorWarning;  // ČERVENÁ pri blikaní
                }
                dc.setColor(borderColor, Graphics.COLOR_WHITE);
                dc.drawRectangle(x, y, barWidth, barHeight);
            }
        }
        
        // ----- KRESLENIE PREDNÝCH PREVODNÍKOV -----
        // Úloha: 2 bary na vrchu, nad 2 najmenšími zadnými (vpravo)
        
        if (frontGearMax > 0 && frontGearIndex != null) {
            
            // Pozícia: 2 najmenšie zadné sú na pozícii (rearGearMax - 2)
            var smallestRearStartX = MARGIN_SIDES + (rearGearMax - 2) * rearBarWidth;
            
            var FRONT_BAR_WIDTH = rearBarWidth;
            var frontStartX = smallestRearStartX;
            
            var frontTopY = MARGIN_TOP;
            
            for (var f = 0; f < frontGearMax; f++) {
                
                // ----- VÝŠKA BARU -----
                // Index 0 (vľavo) = FRONT_HEIGHT_SMALL = 20px
                // Index 1 (vpravo) = FRONT_HEIGHT_LARGE = 30px
                var barHeight = (f == 1) ? FRONT_HEIGHT_LARGE : FRONT_HEIGHT_SMALL;
                
                var x = frontStartX + f * FRONT_BAR_WIDTH;
                var y = frontTopY;
                
                // ----- KRESLENIE BARU -----
                // Prvé: vymaž farbou pozadia
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
                dc.fillRectangle(x, y, FRONT_BAR_WIDTH, barHeight);
                
                // Potom: nakresli bar (vyplnený = aktívny, obrys = neaktívny)
                if (f + 1 == frontGearIndex) {
                    // AKTÍVNY bar = VYPLNENÝ
                    // Pri warning a blik: ČERVENÁ, inak čierna
                    var selectedColor = colorSelected;
                    if (warning && blinkState) {
                        selectedColor = colorWarning;  // ČERVENÁ pri blikaní
                    }
                    dc.setColor(selectedColor, Graphics.COLOR_WHITE);
                    dc.fillRectangle(x, y, FRONT_BAR_WIDTH, barHeight);
                } else {
                    // NEAKTÍVNY bar = OBRYS
                    // Pri warning a blik: ČERVENÁ, inak čierna
                    var borderColor = colorBorder;
                    if (warning && blinkState) {
                        borderColor = colorWarning;  // ČERVENÁ pri blikaní
                    }
                    dc.setColor(borderColor, Graphics.COLOR_WHITE);
                    dc.drawRectangle(x, y, FRONT_BAR_WIDTH, barHeight);
                }
            }
        }
    }
}
