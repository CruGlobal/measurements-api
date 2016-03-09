require 'rails_helper'

RSpec.describe MeasurementType, type: :model do
  let(:ministry) { FactoryGirl.create(:ministry) }

  def stub_gr_post_measurement_type
    WebMock.stub_request(:post, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types")
           .to_return(->(_) { { body: { measurement_type: { id: SecureRandom.uuid } }.to_json } })
  end

  describe '#save' do
    context 'with valid attributes' do
      before do
        @parent_measurement = FactoryGirl.create(:measurement)
        @attributes = {
          perm_link_stub: 'nbr_nonstaff_reporting',
          english: 'Number of Non-Staff Reporting',
          description: 'Number of Non-Staff Reporting',
          localized_name: 'Présenter le Saint-Esprit',
          localized_description: "Nombre de personnes avec lesquelles le ministère de l'Esprit Saint",
          ministry_id: ministry.id,
          locale: 'fr',
          parent_id: @parent_measurement.total_id
        }

        @measurement_type = MeasurementType.new(@attributes)

        stub_gr_post_measurement_type
      end

      it 'creates Measurement and Translation' do
        expect do
          @measurement_type.save
        end.to change(Measurement, :count).by(1).and(change(MeasurementTranslation, :count).by(1))
      end

      context 'but no ministry' do
        it 'creates Measurement' do
          @measurement_type.ministry_id = nil

          expect do
            @measurement_type.save
          end.to change(Measurement, :count).by(1).and(change(MeasurementTranslation, :count).by(0))
        end
      end

      it 'has the right attributes' do
        @measurement_type.save

        measurement = Measurement.last
        expect(measurement.person_id).to be_uuid
        expect(measurement.local_id).to be_uuid
        expect(measurement.total_id).to be_uuid
        expect(measurement.total_id).to_not eq measurement.local_id
        expect(measurement.english).to eq 'Number of Non-Staff Reporting'
        expect(measurement.description).to_not be_nil
        expect(measurement.section).to eq 'other'
        expect(measurement.column).to eq 'other'
        expect(measurement.sort_order).to be 90
        expect(measurement.parent.id).to eq @parent_measurement.id

        translation = MeasurementTranslation.last
        expect(translation.language).to eq 'fr'
        expect(translation.name).to eq 'Présenter le Saint-Esprit'
        expect(translation.description).to eq @attributes[:localized_description]
      end
    end

    context 'with valid attributes' do
      before do
        @attributes = {
          english: 'Number of Non-Staff Reporting',
          description: 'Number of Non-Staff Reporting',
          localized_name: 'Présenter le Saint-Esprit',
          localized_description: "Nombre de personnes avec lesquelles le ministère de l'Esprit Saint",
          ministry_id: ministry.id,
          locale: 'fr'
        }

        @measurement_type = MeasurementType.new(@attributes)

        stub_gr_post_measurement_type
      end

      it 'does not create Measurement and Translation' do
        expect do
          @measurement_type.save
        end.to change(Measurement, :count).by(0).and(change(MeasurementTranslation, :count).by(0))
      end
    end
  end

  describe '#destroy' do
    before do
      @measurement = FactoryGirl.create(:measurement)
      @measurement_type = MeasurementType.new(measurement: @measurement)

      @gr_meas_delete_total_stub =
        WebMock.stub_request(:delete, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{@measurement.total_id}")
      @gr_meas_delete_local_stub =
        WebMock.stub_request(:delete, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{@measurement.local_id}")
      @gr_meas_delete_person_stub =
        WebMock.stub_request(:delete, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{@measurement.person_id}")
    end

    it 'removes Measurement from the db' do
      expect { @measurement_type.destroy }.to change(Measurement, :count).by(-1)
    end

    it 'deletes it from GR' do
      @measurement_type.destroy
      expect(@gr_meas_delete_total_stub).to have_been_requested
      expect(@gr_meas_delete_local_stub).to have_been_requested
      expect(@gr_meas_delete_person_stub).to have_been_requested
    end

    it "only deletes if it doesn't have children" do
      FactoryGirl.create(:measurement, parent: @measurement)

      expect { @measurement_type.destroy }.to raise_error('measurements with children can not be destroyed')
        .and(change(Measurement, :count).by(0))
    end

    it 'also deletes attached translations' do
      FactoryGirl.create(:measurement_translation, measurement: @measurement)
      expect { @measurement_type.destroy }.to change(MeasurementTranslation, :count).by(-1)
    end
  end
end
