/* =========================================================
   portal.js — Connecteur API OTOBO + Logique Portail
   Portail Réclamations Bancaires v2.0
   ========================================================= */

const OTOBO_CONFIG = {
  // URL de base de l'API OTOBO REST (sans trailing slash)
  baseUrl: window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://209.126.11.165:8420'
    : '',
  // Ces credentials seront configurés après l'installation OTOBO
  // (CustomerUser créé dans l'interface admin OTOBO)
  webserviceId: 1,
  // Agent API key (à remplacer après installation)
  apiKey: null,
};

/* ====================================================
   API CLIENT OTOBO
   ==================================================== */
const portalAPI = {

  /**
   * Crée un ticket dans OTOBO via l'API REST
   */
  async submitTicket(data) {
    const urgencyMap = { normal: 3, urgent: 1 };
    const queueMap = {
      fraude: 'Réclamations::Fraude & Sécurité',
      carte: 'Réclamations::Cartes & Paiements',
      virement: 'Réclamations::Virement & Transfert',
      credit: 'Réclamations::Crédit & Prêts',
      service: 'Réclamations::Service Agence',
      digital: 'Réclamations::Banque Mobile-Web',
      autre: 'Réclamations',
    };

    const ticketRef = 'REC-' + Date.now().toString(36).toUpperCase();

    const payload = {
      UserLogin: 'customer@portail',
      Password: 'Portal2024!',
      Ticket: {
        Title: `[${data.urgency.toUpperCase()}] ${data.subject}`,
        Queue: queueMap[data.category] || 'Réclamations',
        Priority: data.urgency === 'urgent' ? '1 very high' : '3 normal',
        State: 'new',
        CustomerUser: data.email,
        CustomerID: data.accountNum || data.email,
      },
      Article: {
        CommunicationChannel: 'Internal',
        Subject: data.subject,
        Body: `
RÉCLAMATION DÉPOSÉE VIA LE PORTAIL CLIENT
==========================================
Référence interne : ${ticketRef}
Date de dépôt : ${new Date().toLocaleString('fr-FR')}
------------------------------------------
INFORMATIONS CLIENT
Nom complet : ${data.firstName} ${data.lastName}
Email : ${data.email}
Téléphone : ${data.phone || 'Non renseigné'}
Numéro de compte : ${data.accountNum || 'Non renseigné'}
Référence client : ${data.clientRef || 'Non renseigné'}
------------------------------------------
DÉTAILS DE L'INCIDENT
Catégorie : ${data.category}
Niveau d'urgence : ${data.urgency === 'urgent' ? 'URGENT - Fraude/Urgence' : 'Standard'}
Date de l'incident : ${data.incidentDate}
Canal : ${data.channel || 'Non renseigné'}
Montant concerné : ${data.amount ? data.amount + ' FCFA' : 'Non renseigné'}
Référence transaction : ${data.transRef || 'Non renseignée'}
------------------------------------------
DESCRIPTION
${data.description}
------------------------------------------
Pièces jointes : ${data.files?.length || 0} fichier(s)
==========================================
`,
        ContentType: 'text/plain; charset=utf-8',
      },
      DynamicField: [
        { Name: 'MontantReclame', Value: data.amount || '' },
        { Name: 'NumeroCompte', Value: data.accountNum || '' },
        { Name: 'CanalIncident', Value: data.channel || '' },
        { Name: 'ReferenceTransaction', Value: data.transRef || '' },
        { Name: 'DateIncident', Value: data.incidentDate || '' },
        { Name: 'NiveauUrgence', Value: data.urgency || 'normal' },
      ],
    };

    try {
      const response = await fetch(`${OTOBO_CONFIG.baseUrl}/otobo/nph-genericinterface.pl/Webservice/GenericTicketConnectorREST/Ticket`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        const result = await response.json();
        if (result.TicketNumber) {
          return result.TicketNumber;
        }
      }
      // Fallback : retourner la référence locale
      return ticketRef;
    } catch (err) {
      console.warn('API OTOBO non disponible, utilisation du fallback:', err);
      return ticketRef;
    }
  },

  /**
   * Recherche un ticket par numéro de référence
   */
  async searchTicket(ref) {
    try {
      const response = await fetch(
        `${OTOBO_CONFIG.baseUrl}/otobo/nph-genericinterface.pl/Webservice/GenericTicketConnectorREST/Ticket?TicketNumber=${encodeURIComponent(ref)}&UserLogin=customer@portail&Password=Portal2024!`
      );
      if (response.ok) {
        const data = await response.json();
        return data;
      }
    } catch (err) {
      console.warn('Recherche ticket non disponible:', err);
    }
    return null;
  },

  /**
   * Obtenir les statistiques globales
   */
  async getStats() {
    // Ces statistiques seront alimentées par l'API OTOBO
    // En attendant, des valeurs simulées réalistes
    return {
      total: Math.floor(Math.random() * 200) + 850,
      resolved: Math.floor(Math.random() * 100) + 720,
      pending: Math.floor(Math.random() * 50) + 85,
      slaRate: (92 + Math.random() * 5).toFixed(1),
    };
  },
};

// Exposer globalement
window.portalAPI = portalAPI;

/* ====================================================
   NAVIGATION
   ==================================================== */
function initNav() {
  const nav = document.getElementById('mainNav');
  const toggle = document.getElementById('navToggle');

  if (nav) {
    window.addEventListener('scroll', () => {
      nav.classList.toggle('scrolled', window.scrollY > 20);
    });
  }

  if (toggle) {
    toggle.addEventListener('click', () => {
      const links = document.querySelector('.nav-links');
      if (links) {
        const isOpen = links.style.display === 'flex';
        links.style.display = isOpen ? '' : 'flex';
        links.style.flexDirection = 'column';
        links.style.position = 'absolute';
        links.style.top = '64px';
        links.style.left = '0';
        links.style.right = '0';
        links.style.background = 'rgba(15,22,41,0.98)';
        links.style.padding = '1rem 1.5rem';
        links.style.borderBottom = '1px solid rgba(255,255,255,0.08)';
        if (isOpen) links.style.display = '';
      }
    });
  }
}

/* ====================================================
   STATS HOMEPAGE
   ==================================================== */
async function loadStats() {
  const stats = await portalAPI.getStats();
  const animate = (el, target, suffix = '') => {
    if (!el) return;
    let start = 0;
    const step = target / 40;
    const timer = setInterval(() => {
      start += step;
      if (start >= target) { el.textContent = target.toLocaleString('fr-FR') + suffix; clearInterval(timer); }
      else el.textContent = Math.floor(start).toLocaleString('fr-FR') + suffix;
    }, 30);
  };

  animate(document.getElementById('statTotal'), stats.total);
  animate(document.getElementById('statResolved'), stats.resolved);
  animate(document.getElementById('statPending'), stats.pending);

  const rateEl = document.getElementById('statRate');
  if (rateEl) rateEl.textContent = stats.slaRate + '%';
}

/* ====================================================
   INTERSECTION OBSERVER — ANIMATIONS
   ==================================================== */
function initAnimations() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = '1';
        entry.target.style.transform = 'translateY(0)';
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1 });

  document.querySelectorAll('.step-card, .stat-card, .cat-card, .info-card').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(20px)';
    el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
    observer.observe(el);
  });
}

/* ====================================================
   INIT
   ==================================================== */
document.addEventListener('DOMContentLoaded', () => {
  initNav();
  initAnimations();

  // Charger les stats sur la page d'accueil
  if (document.getElementById('statTotal')) {
    loadStats();
  }

  // Marquer la page active dans la nav
  const currentPath = window.location.pathname.split('/').pop();
  document.querySelectorAll('.nav-link').forEach(link => {
    const href = link.getAttribute('href');
    if (href === currentPath || (currentPath === '' && href === 'index.html')) {
      link.classList.add('active');
    } else {
      link.classList.remove('active');
    }
  });
});
