// app-hifi.jsx — Production-fidelity composition.

function AppHiFi() {
  return (
    <DesignCanvas>
      <DCSection id="signin" title="1 · SignIn" subtitle="Stacked deck of real artwork. Brand mark + hand-tagline. Apple/email CTAs.">
        <DCArtboard id="signin-hifi" label="SignIn — production" width={HF_W + 24} height={HF_H + 40}><HFSignIn/></DCArtboard>
      </DCSection>
      <DCSection id="home" title="2 · Home" subtitle="Magazine-style featured piece + child rail + recent strip + glass tab bar.">
        <DCArtboard id="home-hifi" label="Home — production" width={HF_W + 24} height={HF_H + 40}><HFHome/></DCArtboard>
      </DCSection>
      <DCSection id="child" title="3 · Child detail" subtitle="Single hero with tinted gradient + chip stats + sectioned grid.">
        <DCArtboard id="child-hifi" label="Child — production" width={HF_W + 24} height={HF_H + 40}><HFChildDetail/></DCArtboard>
      </DCSection>
      <DCSection id="gallery" title="4 · Gallery" subtitle="Crayon-underline section headers, subtle kid-color badges on thumbs.">
        <DCArtboard id="gallery-hifi" label="Gallery — production" width={HF_W + 24} height={HF_H + 40}><HFGallery/></DCArtboard>
      </DCSection>
      <DCSection id="styles" title="5 · Style picker" subtitle="Lock-screen preview at top, 4-col grid of styles, generate CTA.">
        <DCArtboard id="styles-hifi" label="StylePicker — production" width={HF_W + 24} height={HF_H + 40}><HFStylePicker/></DCArtboard>
      </DCSection>
      <DCSection id="paywall" title="6 · Paywall" subtitle="Wallpaper trio hero with crown · checklist · two plan cards · trial CTA.">
        <DCArtboard id="paywall-hifi" label="Paywall — production" width={HF_W + 24} height={HF_H + 40}><HFPaywall/></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<AppHiFi/>);
