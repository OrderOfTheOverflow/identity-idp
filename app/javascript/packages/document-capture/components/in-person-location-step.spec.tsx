import sinon from 'sinon';
import { useContext } from 'react';
import { render } from '@testing-library/react';
import { getAllByRole } from '@testing-library/dom';
import userEvent from '@testing-library/user-event';
import { useSandbox } from '@18f/identity-test-helpers';
import AnalyticsContext, { AnalyticsContextProvider } from '../context/analytics';
import InPersonLocationStep, { LOCATIONS_URL } from './in-person-location-step';
import InPersonLocationPostOfficeSearchStep from './in-person-location-post-office-search-step';
import { ADDRESS_SEARCH_URL } from './address-search';
import InPersonContext from '../context/in-person';

describe('InPersonLocationStep', () => {
  const DEFAULT_PROPS = {
    toPreviousStep() {},
    onChange() {},
    value: {},
    registerField() {},
  };

  const sandbox = useSandbox();

  beforeEach(() => {
    sandbox
      .stub(window, 'fetch')
      .withArgs(LOCATIONS_URL)
      .resolves({
        json: () => Promise.resolve([{ name: 'Baltimore' }]),
      } as Response)
      .withArgs(ADDRESS_SEARCH_URL)
      .resolves({
        json: () =>
          Promise.resolve([
            {
              address: '100 Main St, South Fulton, Tennessee, 38257',
              location: { latitude: 36.501462000000004, longitude: -88.875981 },
              street_address: '100 Main St',
              city: 'South Fulton',
              state: 'TN',
              zip_code: '38257',
            },
          ]),
      } as Response);
  });

  it('logs step submission with selected location', async () => {
    const trackEvent = sinon.stub();
    function MetadataValue() {
      return <>{JSON.stringify(useContext(AnalyticsContext).submitEventMetadata)}</>;
    }
    const { findByText } = render(
      <AnalyticsContextProvider trackEvent={trackEvent}>
        <MetadataValue />
        <InPersonLocationStep {...DEFAULT_PROPS} />
      </AnalyticsContextProvider>,
    );

    const item = await findByText('Baltimore — in_person_proofing.body.location.post_office');
    const button = getAllByRole(item.closest('.location-collection-item')!, 'button')[0];

    await userEvent.click(button);

    await findByText('{"selected_location":"Baltimore"}');
  });

  it('allows search by address when enabled', async () => {
    const { findByText, findByLabelText } = render(
      <InPersonContext.Provider value={{ arcgisSearchEnabled: true }}>
        <InPersonLocationPostOfficeSearchStep {...DEFAULT_PROPS} />
      </InPersonContext.Provider>,
    );

    await userEvent.type(
      await findByLabelText('in_person_proofing.body.location.po_search.address_search_label'),
      '100 main',
    );
    await userEvent.click(
      await findByText('in_person_proofing.body.location.po_search.search_button'),
    );
    await findByText('100 Main St, South Fulton, Tennessee, 38257');
    expect(window.fetch).to.have.been.calledWith(
      LOCATIONS_URL,
      sandbox.match({
        body: '{"address":{"street_address":"100 Main St","city":"South Fulton","state":"TN","zip_code":"38257"}}',
        method: 'post',
      }),
    );
  });
});
