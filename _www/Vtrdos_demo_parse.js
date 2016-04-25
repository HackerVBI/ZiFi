(function(){
	var top = document.querySelector('frame[name="demoztop"]'),
		party = document.querySelector('frame[name="demozmid"]'),
		c = document.querySelector('frame[name="demozdown"]'),
		itop,iparty,ic,
		years,parties,demos,
		demo,popup,
		out = [],
		total, current, cpt,cdm;

	itop = top.contentDocument || top.contentWindow.document;

	years = itop.querySelectorAll('nobr a[href*="party.php"]')

	current = 0;
	total = years.length;

	getYear(years[current]);

	function getYear(yearNode){		
		party.onload = fetchParties(yearNode.textContent)
		yearNode.click()
	}

	function getNextYear(){
		current++;
		if (current < years.length){
			getYear(years[current]);
		} else {
			popup = window.open("","","resizable=1;width=640,height=480");
			popup.document.write(JSON.stringify(out));
		}
	}

	function fetchParties(year){
		cpt = 0;

		return function(){
			iparty = party.contentDocument || party.contentWindow.document;
			parties = iparty.querySelectorAll('nobr a')
			getParty(year,parties[cpt])
		}
	}

	function nextParty(year){
		cpt++;
		if (cpt < parties.length){
			getParty(year,parties[cpt]);
		} else {
			getNextYear();
		}
	}

	function getParty(year,partyNode){
		c.onload = fetchDemos(year,partyNode.textContent)
		partyNode.click()
	}

	function fetchDemos(year,party){
		return function(){
			ic = c.contentDocument || c.contentWindow.document;
			cdm = ic.querySelector('a[target]');
			
			demo = {
				year: year,
				party: party,
				url: 'http://vtrdos.ru/' + cdm.getAttribute('href')
			}

			out.push(demo)
			nextParty(year)
		}
	}
})()